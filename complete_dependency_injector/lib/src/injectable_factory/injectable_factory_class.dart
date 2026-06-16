
import '../dependencies/dependencies.dart';
import '../injectable/injectable.dart';
import '../injector_token/injector_token.dart';

/// A factory responsible for creating instances of an injectable type.
///
/// An [InjectableFactory] describes what dependencies it needs, what scope it
/// belongs to, and how to create the instance.
class InjectableFactory {
  /// The metadata describing the dependencies required by this factory.
  final DependencyData dependencyData;

  /// The scope in which the created instance should reside.
  final InjectableScope scope;

  /// The string representation of the type this factory builds.
  final String buildsType;

  final Function _creator;

  InjectableFactory._({DependencyData? dependencyData, InjectableScope? scope, required Type buildsType, required Function creator})
      : dependencyData = dependencyData ?? DependencyDataBuilder.empty,
        scope = scope ?? InjectableScope.root,
        buildsType = InjectorToken.fromType(buildsType).tokenRepresentation,
        _creator = creator;

  /// Creates a new instance of the injectable.
  ///
  /// * [dependencies]: The resolved dependencies required by this factory.
  ///
  /// Returns a [Future] that completes with the created instance.
  Future<Object> createInjectable(Dependencies dependencies) {
    final instanceOrFuture  = _creator(dependencies);
    if(instanceOrFuture is InjectableWithReadyInterface) return instanceOrFuture.injectableReady.then((value) => instanceOrFuture);
    if(instanceOrFuture is Future<Object>) return instanceOrFuture;
    return Future.value(instanceOrFuture);
  } 

  /// Creates an [InjectableFactory] for a type that has dependencies.
  ///
  /// * [dependencyData]: The description of the required dependencies.
  /// * [creator]: A function that takes [Dependencies] and returns an instance of [T].
  /// * [scope]: The optional [InjectableScope] for the created instance.
  static InjectableFactory withDependencies<T extends Object>(DependencyData dependencyData, InjectableInstanceCreatorWithDependencies<T> creator, {InjectableScope? scope}) =>
      InjectableFactory._(buildsType: T, creator: creator, scope: scope, dependencyData: dependencyData);

  /// Creates an [InjectableFactory] for a type that has no dependencies.
  ///
  /// * [creator]: A function that returns an instance of [T].
  /// * [scope]: The optional [InjectableScope] for the created instance.
  static InjectableFactory withoutDependencies<T extends Object>(InjectableInstanceCreatorWithoutDependencies<T> creator, {InjectableScope? scope}) =>
      InjectableFactory._(buildsType: T, creator: (_) => creator(), scope: scope);
}

/// A function type that creates an instance of [T] using resolved [dependencies].
typedef InjectableInstanceCreatorWithDependencies<T extends Object> = T Function(Dependencies dependencies);

/// A function type that creates an instance of [T] without any dependencies.
typedef InjectableInstanceCreatorWithoutDependencies<T extends Object> = T Function();
