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

  Future<Dependencies> resolveDependencies(DependencyData requested) async {
    // Resolve into a private copy: the same DependencyData (a factory's, or
    // one a widget keeps) may be resolved by several injectors at once.
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

  /// Tokens whose instances are being set up right now, across all injectors,
  /// as `injectorId:token`. Looking up uncached dependencies is synchronous
  /// all the way down, so a token seen twice on this path is a cycle.
  static final List<String> _resolutionPath = [];

  InjectorInjectableInstanceScopeContainer _tryFindOrInstantiateNewInstanceOnCorrectScope(String provideTokenRep, bool optional) {
    if (parentResolver != null && !_providers.containsKey(provideTokenRep)) {
      return parentResolver!._tryFindOrInstantiateNewInstanceOnCorrectScope(provideTokenRep, optional);
    }

    if (!_providers.containsKey(provideTokenRep)) {
      if (!optional) throw InjectorError("No provider found for $provideTokenRep");
      // An optional dependency that nothing provides resolves to null.
      return InjectorInjectableInstanceScopeContainer(_myId, Future.value(null));
    }
    if (injectableInstances.containsKey(provideTokenRep)) return injectableInstances[provideTokenRep]!;

    final pathEntry = "$_myId:$provideTokenRep";
    if (_resolutionPath.contains(pathEntry)) {
      final cycle = [..._resolutionPath.skip(_resolutionPath.indexOf(pathEntry)), pathEntry].map((e) => e.substring(e.indexOf(':') + 1));
      throw InjectorError("InjectorResolver: Circular dependency: ${cycle.join(' -> ')}");
    }
    _resolutionPath.add(pathEntry);
    try {
      return _instantiateOnThisScope(provideTokenRep, optional);
    } finally {
      _resolutionPath.removeLast();
    }
  }

  InjectorInjectableInstanceScopeContainer _instantiateOnThisScope(String provideTokenRep, bool optional) {
    final provider = _providers[provideTokenRep]!;
    if (provider.useExisting != null) {
      // Not cached here: the target caches its own instance, so a retry after
      // a failure, and disposal, both go through the target alone.
      return _tryFindOrInstantiateNewInstanceOnCorrectScope(provider.useExisting!, optional).forReference(name: provider.name);
    }

    if (!provider.shouldHaveFactory && provider.useValue != null) {
      return injectableInstances[provideTokenRep] = InjectorInjectableInstanceScopeContainer(_myId, Future.value(provider.useValue!), name: provider.name);
    }

    if (provider.shouldHaveFactory && !_factories.containsKey(provideTokenRep)) {
      throw InjectorError("InjectorResolver: Could not instantiate non-optional injectable $provideTokenRep");
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
    container = InjectorInjectableInstanceScopeContainer(_myId, serviceFuture, name: provider.name);
    return injectableInstances[provideTokenRep] = container;
  }

  Future<void> dispose() async {
    await Future.wait(childResolvers.map((e) => e.dispose()));
    final disposalFutures = <Future<void>>[];
    for (final container in injectableInstances.values) {
      if (container.parentInjectorId == _myId) {
        // A service whose creation failed has nothing to dispose; its error
        // already went to whoever asked for it.
        final instanceFuture = container.serviceFuture.then<Object?>((instance) => instance, onError: (_) => null);
        disposalFutures.add(instanceFuture.then((instance) async {
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
