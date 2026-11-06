
import '../dependencies/dependencies.dart';
import '../injectable/injectable.dart';
import '../injector_token/injector_token.dart';
import '../injector/injector_errors.dart';

/// A factory responsible for creating instances of an injectable type.
///
/// An [InjectableFactory] describes what dependencies a type needs and how to
/// create it. Where the instance lives is decided by where the type is
/// provided: the injector whose [Provider] is used creates and caches it.
class InjectableFactory {
  /// The metadata describing the dependencies required by this factory.
  final DependencyData dependencyData;

  /// The string representation of the type this factory builds.
  final String buildsType;

  final Function _creator;

  InjectableFactory._({DependencyData? dependencyData, required Type buildsType, required Function creator})
      : dependencyData = dependencyData ?? DependencyDataBuilder.empty,
        buildsType = InjectorToken.fromType(buildsType).tokenRepresentation,
        _creator = creator;

  /// Creates a new instance of the injectable.
  ///
  /// * [dependencies]: The resolved dependencies required by this factory.
  ///
  /// Returns a [Future] that completes with the created instance.
  Future<Object> createInjectable(Dependencies dependencies) {
    final instanceOrFuture  = _creator(dependencies);
    if (instanceOrFuture is InjectableWithReadyInterface) {
      return instanceOrFuture.injectableReady.then((isReady) {
        if (!isReady) throw InjectorError("$buildsType reported that it is not ready (setInjectableReadyResult(false))");
        return instanceOrFuture;
      });
    }
    if(instanceOrFuture is Future<Object>) return instanceOrFuture;
    return Future.value(instanceOrFuture);
  } 

  /// Creates an [InjectableFactory] for a type that has dependencies.
  ///
  /// * [dependencyData]: The description of the required dependencies.
  /// * [creator]: A function that takes [Dependencies] and returns an instance of [T].
  static InjectableFactory withDependencies<T extends Object>(DependencyData dependencyData, InjectableInstanceCreatorWithDependencies<T> creator) =>
      InjectableFactory._(buildsType: T, creator: creator, dependencyData: dependencyData);

  /// Creates an [InjectableFactory] for a type that has no dependencies.
  ///
  /// * [creator]: A function that returns an instance of [T].
  static InjectableFactory withoutDependencies<T extends Object>(InjectableInstanceCreatorWithoutDependencies<T> creator) =>
      InjectableFactory._(buildsType: T, creator: (_) => creator());
}

/// A function type that creates an instance of [T] using resolved [dependencies].
typedef InjectableInstanceCreatorWithDependencies<T extends Object> = T Function(Dependencies dependencies);

/// A function type that creates an instance of [T] without any dependencies.
typedef InjectableInstanceCreatorWithoutDependencies<T extends Object> = T Function();
