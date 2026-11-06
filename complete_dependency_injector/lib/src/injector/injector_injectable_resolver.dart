import 'dart:async';
import '../library_src.dart';
import '../provider/provide_strategy.dart';
import 'injector_injectable_instance_container.dart';

class InjectorInjectableResolver {
  static int _idCounter = 1;
  final int _myId;

  final Map<String, ProvideStrategy> _providers = {};
  final Map<String, InjectorInjectableInstanceScopeContainer> injectableInstances = {};
  static final Map<String, InjectableFactory> _factories = {};

  Map<String, InjectableFactory> get factories => _factories;
  late InjectorInjectableResolver? parentResolver;
  late InjectorInjectableResolver rootResolver;
  final List<InjectorInjectableResolver> childResolvers = [];
  final InjectorDebugOptions debugOptions;

  /// Instances this resolver created, in the order they finished creating.
  /// A service always finishes after the services it depends on, so disposing
  /// in reverse disposes dependents before their dependencies.
  final List<Object?> _createdInOrder = [];
  Future<void>? _disposeFuture;
  bool get isDisposed => _disposeFuture != null;

  InjectorInjectableResolver(List<Provider> providers, this.debugOptions, {this.parentResolver}) : _myId = _idCounter {
    if (parentResolver?.isDisposed ?? false) throw InjectorError("Cannot create a child of a disposed Injector");
    parentResolver?.childResolvers.add(this);
    rootResolver = parentResolver?.rootResolver ?? this;
    _idCounter++;
    _providers.addAllFromProviderListSafe(
      providers,
      message: "InjectorInjectableResolver: Provider strategy already exists in map. ",
      safe: debugOptions.errorOnDuplicateScopeProviderStrategy,
    );
    injectableInstances[InjectorToken.fromType(Injector).tokenRepresentation] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(this));
  }

  Future<Dependencies> resolveDependencies(DependencyData data) async {
    _throwIfDisposed();
    await Future.wait(data.all.values.map((e) async {
      final instanceContainer = _tryFindOrInstantiateNewInstanceOnCorrectScope(e.tokenString, e.optional);
      e.providedName = instanceContainer.name;
      e.instance = await instanceContainer.serviceFuture;
    }));
    return Dependencies(data);
  }

  Future<T> getService<T>([Object? token]) async {
    final tokenString = InjectorToken.fromTokenOrType(token ?? T).tokenRepresentation;
    final container = _tryFindOrInstantiateNewInstanceOnCorrectScope(tokenString, false);
    return (await container.serviceFuture) as T;
  }

  Future<T?> getServiceOrNull<T>([Object? token]) async {
    final tokenString = InjectorToken.fromTokenOrType(token ?? T).tokenRepresentation;
    final container = _tryFindOrInstantiateNewInstanceOnCorrectScope(tokenString, true);
    return (await container.serviceFuture) as T?;
  }

  void _throwIfDisposed() {
    if (isDisposed) throw InjectorError("This Injector has been disposed");
  }

  InjectorInjectableInstanceScopeContainer _tryFindOrInstantiateNewInstanceOnCorrectScope(String provideTokenRep, bool optional) {
    _throwIfDisposed();
    if (parentResolver != null && !_providers.containsKey(provideTokenRep)) {
      return parentResolver!._tryFindOrInstantiateNewInstanceOnCorrectScope(provideTokenRep, optional);
    }

    if (!_providers.containsKey(provideTokenRep)) {
      if (!optional) throw InjectorError("No provider found for $provideTokenRep");
      // An optional dependency that nothing provides resolves to null.
      return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null));
    }
    final provider = _providers[provideTokenRep]!;
    if (injectableInstances.containsKey(provideTokenRep)) return injectableInstances[provideTokenRep]!;
    if (provider.useExisting != null) {
      injectableInstances[provideTokenRep] = _tryFindOrInstantiateNewInstanceOnCorrectScope(
        provider.useExisting!,
        optional,
      ).forReference(name: provider.name);
      if (injectableInstances.containsKey(provideTokenRep)) return injectableInstances[provideTokenRep]!;
      //if (optional) return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null), name: provider.name);
      throw InjectorError("InjectorResolver: Could not instantiate non-optional injectable $provideTokenRep");
    }

    if (!provider.shouldHaveFactory && provider.useValue != null) {
      return injectableInstances[provideTokenRep] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(provider.useValue!), name: provider.name);
    }

    if (provider.shouldHaveFactory && !_factories.containsKey(provideTokenRep) /* && !optional */) {
      throw InjectorError("InjectorResolver: Could not instantiate non-optional injectable $provideTokenRep");
    }
    //if(!_factories.containsKey(provideTokenRep) && optional) return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null), name: provider.name);
    final factory = _factories[provideTokenRep]!;
    final dependenciesFuture = resolveDependencies(factory.dependencyData);
    // The injector that provides the token owns the instance: one per
    // providing injector, disposed with it.
    return injectableInstances[provideTokenRep] = InjectorInjectableInstanceScopeContainer(
      _myId,
      dependenciesFuture.then((Dependencies dependencies) => factory.createInjectable(dependencies)).then((instance) {
        _createdInOrder.add(instance);
        return instance;
      }),
      name: provider.name,
    );
  }

  /// Disposes child resolvers first, then every instance this resolver owns,
  /// each exactly once, dependents before their dependencies. Calling it again
  /// returns the same future.
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    final errors = <Object>[];
    final stackTraces = <StackTrace>[];
    void record(Object error, StackTrace stackTrace) {
      errors.add(error);
      stackTraces.add(stackTrace);
    }

    for (final child in List.of(childResolvers)) {
      try {
        await child.dispose();
      } catch (e, s) {
        record(e, s);
      }
    }

    // Aliases share their target's future, so collect each owned future once.
    final owned = <Future<Object?>>{
      for (final container in injectableInstances.values)
        if (container.parentInjectorId == _myId) container.serviceFuture,
    };
    // Let in-flight creations finish. A failed creation was already reported to
    // whoever requested it, so it is not rethrown here.
    final settled = await Future.wait(owned.map((f) => f.then<Object?>((v) => v, onError: (_) => null)));

    final created = _createdInOrder.reversed.toList();
    final values = settled.where((instance) => !_createdInOrder.contains(instance));
    final toDispose = <Object?>{...created, ...values};
    for (final instance in toDispose) {
      if (instance is InjectableWithDisposeInterface && instance is! Injector && instance is! InjectorInjectableResolver) {
        try {
          await instance.dispose();
        } catch (e, s) {
          record(e, s);
        }
      }
    }

    injectableInstances.clear();
    _createdInOrder.clear();
    parentResolver?.childResolvers.remove(this);
    if (errors.isNotEmpty) Error.throwWithStackTrace(errors.first, stackTraces.first);
  }

  void registerFactory(InjectableFactory factory) {
    assert(
      debugOptions.allowFactoryReplacement || (!debugOptions.allowFactoryReplacement && !_factories.keys.contains(factory.buildsType)),
      "A factory already exists for ${factory.buildsType}",
    );
    _factories[factory.buildsType] = factory;
  }
}

extension _DependencyTokenStringDependencyMapSafeAddAll on Map<String, ProvideStrategy> {
  void addAllFromProviderListSafe(List<Provider> list, {safe = false, message = ""}) {
    for (var provider in list) {
      addAllFromStrategyListSafe(provider.strategies, safe: safe, message: message + " Strategies from: ${provider.primaryToken}");
    }
  }

  void addAllFromStrategyListSafe(Iterable<ProvideStrategy> list, {safe = false, message = ""}) {
    for (var strategy in list) {
      if (safe && containsKey(strategy.provides)) throw InjectorError("$message, Collision on: ${strategy.provides}");
      this[strategy.provides] = strategy;
    }
  }
}
