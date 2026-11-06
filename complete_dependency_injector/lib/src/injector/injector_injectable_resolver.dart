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

  InjectorInjectableResolver(List<Provider> providers, this.debugOptions, {this.parentResolver}) : _myId = _idCounter {
    rootResolver = parentResolver ?? this;
    _idCounter++;
    _providers.addAllFromProviderListSafe(
      providers,
      message: "InjectorInjectableResolver: Provider strategy already exists in map. ",
      safe: debugOptions.errorOnDuplicateScopeProviderStrategy,
    );
    injectableInstances[InjectorToken.fromType(Injector).tokenRepresentation] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(this));
  }

  Future<Dependencies> resolveDependencies(DependencyData data) async {
    // The same DependencyData is resolved by every injector that builds a
    // factory's type, and by every ViewModel that shares one. Results are kept
    // per call so one resolution can't overwrite another's instances.
    final instances = <String, Object?>{};
    final providedNames = <String, String?>{};
    await Future.wait(data.all.values.map((e) async {
      final instanceContainer = _tryFindOrInstantiateNewInstanceOnCorrectScope(e.tokenString, e.optional);
      providedNames[e.tokenString] = e.providedName = instanceContainer.name;
      instances[e.tokenString] = e.instance = await instanceContainer.serviceFuture;
    }));
    return Dependencies(data, instances: instances, providedNames: providedNames);
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

  InjectorInjectableInstanceScopeContainer _tryFindOrInstantiateNewInstanceOnCorrectScope(String provideTokenRep, bool optional) {
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
      dependenciesFuture.then((Dependencies dependencies) => factory.createInjectable(dependencies)),
      name: provider.name,
    );
  }

  Future<void> dispose() async {
    await Future.wait(childResolvers.map((e) => e.dispose()));
    final disposalFutures = <Future<void>>[];
    for (final container in injectableInstances.values) {
      if (container.parentInjectorId == _myId) {
        disposalFutures.add(container.serviceFuture.then((instance) async {
          if (instance is InjectableWithDisposeInterface && instance is! Injector && instance is! InjectorInjectableResolver) {
            await instance.dispose();
          }
        }));
      }
    }
    await Future.wait(disposalFutures);
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
