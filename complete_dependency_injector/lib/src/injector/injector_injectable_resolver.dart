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

  InjectorInjectableResolver(Injector owner, List<Provider> providers, this.debugOptions, {this.parentResolver}) : _myId = _idCounter {
    rootResolver = parentResolver ?? this;
    _idCounter++;
    _providers.addAllFromProviderListSafe(
      providers,
      message: "InjectorInjectableResolver: Provider strategy already exists in map. ",
      safe: debugOptions.errorOnDuplicateScopeProviderStrategy,
    );
    // Each injector provides itself, so asking for Injector returns the
    // closest one.
    injectableInstances[_injectorToken] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(owner));
  }

  Future<Dependencies> resolveDependencies(DependencyData requested) async {
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

  InjectorInjectableInstanceScopeContainer _tryFindOrInstantiateNewInstanceOnCorrectScope(String provideTokenRep, bool optional) {
    if (injectableInstances.containsKey(provideTokenRep)) return injectableInstances[provideTokenRep]!;

    if (parentResolver != null && !_providers.containsKey(provideTokenRep)) {
      return parentResolver!._tryFindOrInstantiateNewInstanceOnCorrectScope(provideTokenRep, optional);
    }

    if (!_providers.containsKey(provideTokenRep)) {
      if (!optional) throw InjectorError("No provider found for $provideTokenRep");
      // An optional dependency that nothing provides resolves to null.
      return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null), unprovided: true);
    }
    final provider = _providers[provideTokenRep]!;

    if (!provider.shouldHaveFactory && provider.useValue != null) {
      return injectableInstances[provideTokenRep] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(provider.useValue!), name: provider.name);
    }

    final pathKey = "$_myId:$provideTokenRep";
    final cycleStart = _resolutionPath.indexOf(pathKey);
    if (cycleStart != -1) {
      final cycle = [..._resolutionPath.sublist(cycleStart), pathKey].map((e) => e.substring(e.indexOf(':') + 1));
      throw InjectorError("InjectorResolver: Circular dependency: ${cycle.join(' -> ')}");
    }
    _resolutionPath.add(pathKey);
    try {
      return _instantiate(provideTokenRep, provider, optional);
    } finally {
      _resolutionPath.removeLast();
    }
  }

  InjectorInjectableInstanceScopeContainer _instantiate(String provideTokenRep, ProvideStrategy provider, bool optional) {
    if (provider.useExisting != null) {
      final target = _tryFindOrInstantiateNewInstanceOnCorrectScope(provider.useExisting!, optional).forReference(name: provider.name);
      // Don't cache "nothing provides the target": a later required lookup
      // must still fail.
      if (target.unprovided) return target;
      return injectableInstances[provideTokenRep] = target;
    }

    if (!_factories.containsKey(provideTokenRep)) {
      throw InjectorError("InjectorResolver: Could not instantiate non-optional injectable $provideTokenRep");
    }
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
