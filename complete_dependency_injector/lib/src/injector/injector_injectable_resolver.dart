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

  /// Tokens currently being resolved, innermost last, as "resolverId:token".
  /// Resolution walks the graph synchronously before its first await, so a
  /// token that shows up here again is a cycle.
  static final List<String> _resolutionPath = [];

  static final String _injectorToken = InjectorToken.fromType(Injector).tokenRepresentation;

  /// Instances this resolver created, in the order they finished creating.
  /// A service always finishes after the services it depends on, so disposing
  /// in reverse disposes dependents before their dependencies.
  final List<Object?> _createdInOrder = [];
  Future<void>? _disposeFuture;
  bool get isDisposed => _disposeFuture != null;

  InjectorInjectableResolver(Injector owner, List<Provider> providers, this.debugOptions, {this.parentResolver}) : _myId = _idCounter {
    if (parentResolver?.isDisposed ?? false) throw InjectorError("Cannot create a child of a disposed Injector");
    parentResolver?.childResolvers.add(this);
    rootResolver = parentResolver?.rootResolver ?? this;
    _idCounter++;
    _providers.addAllFromProviderListSafe(
      providers,
      message: "InjectorInjectableResolver: Provider strategy already exists in map. ",
      safe: debugOptions.errorOnDuplicateScopeProviderStrategy,
    );
    // Each injector provides itself, so asking for Injector returns the
    // closest one, unless it was given another Injector to provide.
    if (!_providers.containsKey(_injectorToken)) {
      injectableInstances[_injectorToken] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(owner));
    }
  }

  Future<Dependencies> resolveDependencies(DependencyData requested) async {
    _throwIfDisposed();
    // Fill a copy: the same DependencyData (a factory's, or a view model's)
    // can be resolved by several injectors at once.
    final data = requested.copyUnresolved();
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
    if (injectableInstances.containsKey(provideTokenRep)) return injectableInstances[provideTokenRep]!;

    if (parentResolver != null && !_providers.containsKey(provideTokenRep)) {
      return parentResolver!._tryFindOrInstantiateNewInstanceOnCorrectScope(provideTokenRep, optional);
    }

    if (!_providers.containsKey(provideTokenRep)) {
      if (!optional) throw InjectorError("No provider found for ${describeToken(provideTokenRep)}");
      // An optional dependency that nothing provides resolves to null.
      return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null), unprovided: true);
    }
    final pathKey = "$_myId:$provideTokenRep";
    final cycleStart = _resolutionPath.indexOf(pathKey);
    if (cycleStart != -1) {
      final cycle = [..._resolutionPath.sublist(cycleStart), pathKey].map((e) => e.substring(e.indexOf(':') + 1));
      throw InjectorError("InjectorResolver: Circular dependency: ${cycle.join(' -> ')}");
    }
    _resolutionPath.add(pathKey);
    try {
      return _instantiate(provideTokenRep, _providers[provideTokenRep]!, optional);
    } finally {
      _resolutionPath.removeLast();
    }
  }

  InjectorInjectableInstanceScopeContainer _instantiate(String provideTokenRep, ProvideStrategy provider, bool optional) {
    if (provider.useExisting != null) {
      // Not cached here: the target caches its own instance, so it is disposed
      // once, a failure can be retried, and "nothing provides the target" is
      // never remembered for a later required lookup.
      return _tryFindOrInstantiateNewInstanceOnCorrectScope(provider.useExisting!, optional).forReference(name: provider.name);
    }

    if (!provider.shouldHaveFactory && provider.useValue != null) {
      _createdInOrder.add(provider.useValue);
      return injectableInstances[provideTokenRep] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(provider.useValue!), name: provider.name);
    }

    if (!_factories.containsKey(provideTokenRep)) {
      // Optional lookups (getServiceOrNull, optional dependencies) treat a
      // missing factory like a missing provider.
      if (optional) return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null), unprovided: true);
      final name = describeToken(provideTokenRep);
      throw InjectorError("No factory registered for $name. It is provided, but nothing can build it: call registerFactory($name.Factory) or registerFactories([...]) at startup.");
    }
    final factory = _factories[provideTokenRep]!;
    final dependenciesFuture = resolveDependencies(factory.dependencyData);
    late final InjectorInjectableInstanceScopeContainer container;
    final serviceFuture = dependenciesFuture.then((Dependencies dependencies) => factory.createInjectable(dependencies)).catchError((Object error, StackTrace stackTrace) {
      // Don't cache a failure: the next request tries again.
      if (identical(injectableInstances[provideTokenRep], container)) injectableInstances.remove(provideTokenRep);
      Error.throwWithStackTrace(error, stackTrace);
    });
    // The injector that provides the token owns the instance: one per
    // providing injector, disposed with it.
    container = InjectorInjectableInstanceScopeContainer(
      _myId,
      serviceFuture.then((instance) {
        if (isDisposed) {
          // Created after this injector was disposed: dispose it straight away.
          _disposeInstance(instance);
        } else {
          _createdInOrder.add(instance);
        }
        return instance;
      }),
      name: provider.name,
    );
    return injectableInstances[provideTokenRep] = container;
  }

  /// Disposes child resolvers first, then every instance this resolver owns,
  /// each exactly once, dependents before their dependencies. Calling it again
  /// returns the same future. It does not wait for services that are still
  /// being created; those are disposed as soon as they finish.
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    // Run services' dispose() after the current event, never synchronously
    // inside the caller (for example while Flutter is tearing down a tree).
    await Future<void>.value();
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

    // Instances still being created dispose themselves when they finish (see
    // _instantiate). A Set, so an object provided twice is disposed once.
    final created = <Object?>{..._createdInOrder.reversed};
    _createdInOrder.clear();
    injectableInstances.clear();
    parentResolver?.childResolvers.remove(this);

    for (final instance in created) {
      try {
        await _disposeInstance(instance);
      } catch (e, s) {
        record(e, s);
      }
    }
    if (errors.isNotEmpty) Error.throwWithStackTrace(errors.first, stackTraces.first);
  }

  static Future<void> _disposeInstance(Object? instance) async {
    if (instance is InjectableWithDisposeInterface && instance is! Injector && instance is! InjectorInjectableResolver) {
      await instance.dispose();
    }
  }

  /// A readable name for a token string: the type name for a type token, the
  /// identifier in quotes for a string token.
  static String describeToken(String tokenRep) {
    if (tokenRep.startsWith('type_')) {
      final name = tokenRep.substring(5);
      final dash = name.lastIndexOf('-');
      return dash == -1 ? name : name.substring(0, dash);
    }
    if (tokenRep.startsWith('string_')) return "'${tokenRep.substring(7)}'";
    return tokenRep;
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
      final existing = this[strategy.provides];
      // Two providers asking for the same type to be built by its factory (for
      // example Provider(Foo) and Provider.factory(IFoo, fromDerived: Foo))
      // agree, so they are not a collision.
      final sameFactory = existing != null && existing.shouldHaveFactory && strategy.shouldHaveFactory;
      if (safe && existing != null && !sameFactory) {
        throw InjectorError("$message, Collision on: ${InjectorInjectableResolver.describeToken(strategy.provides)}");
      }
      this[strategy.provides] = strategy;
    }
  }
}
