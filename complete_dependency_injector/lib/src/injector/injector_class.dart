import 'dart:async';

import '../library_src.dart';
import 'injector_injectable_resolver.dart';

/// The main entry point for dependency injection.
///
/// An [Injector] manages a collection of [Provider]s and is responsible for
/// resolving dependencies and providing services.
///
/// It supports hierarchical injectors, allowing you to create child injectors
/// that inherit and can override providers from their parent.
class Injector implements InjectableWithDisposeInterface {
  late InjectorInjectableResolver _resolver;
  final InjectorDebugOptions _debugOptions;

  /// Creates a new [Injector] instance.
  ///
  /// * [providers]: A list of [Provider]s that define how services are created.
  /// * [debugOptions]: Optional debugging configuration.
  /// * [parent]: An optional parent [Injector]. If provided, this injector will
  ///   look up dependencies in the parent if they are not found locally.
  Injector(List<Provider> providers, {InjectorDebugOptions? debugOptions, Injector? parent})
      : _debugOptions = debugOptions ?? parent?._debugOptions ?? InjectorDebugOptions(),
        super() {
    _resolver = InjectorInjectableResolver(this, providers, _debugOptions, parentResolver: parent?._resolver);
  }

  /// Registers a list of [InjectableFactory]s with the injector.
  void registerFactories(List<InjectableFactory> factories) {
    for (var e in factories) {
      registerFactory(e);
    }
  }

  /// Registers a single [InjectableFactory] with the injector.
  void registerFactory(InjectableFactory factory) {
    _resolver.registerFactory(factory);
  }

  /// Resolves all dependencies specified in [dependencies].
  ///
  /// Returns a [Future] that completes with a [Dependencies] container.
  Future<Dependencies> resolveDependencies(DependencyData dependencies) => _resolver.resolveDependencies(dependencies);

  /// Resolves dependencies and then invokes [invokableFunction] with those dependencies.
  ///
  /// This is a convenience method for running logic that requires multiple services.
  Future<T> invokeApplyWithDependencies<T>(DependencyData dependencyData, Function invokableFunction) =>
      resolveDependencies(dependencyData).then((dependencies) => dependencies.invokeApply<T>(invokableFunction));

  /// Gets a service of type [T].
  ///
  /// * [tokenOrType]: An optional token (e.g., [InjectorToken]) or [Type] to
  ///   disambiguate between different implementations of the same type.
  ///
  /// Throws an error if the service cannot be resolved.
  Future<T> getService<T>([Object? tokenOrType]) => _resolver.getService<T>(tokenOrType);

  /// Gets a service of type [T], or returns `null` if it cannot be resolved.
  ///
  /// * [tokenOrType]: An optional token (e.g., [InjectorToken]) or [Type].
  Future<T?> getServiceOrNull<T>([Object? tokenOrType]) => _resolver.getServiceOrNull<T>(tokenOrType);

  @override
  Future<void> dispose() => Future.wait([_resolver.dispose()]);
}
