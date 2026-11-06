import '../library_src.dart';
import 'dependency_class.dart';

/// A container for resolved dependencies.
/// When
/// This class provides methods to retrieve specific dependencies by type or token.
class Dependencies {
  final DependencyData _dependencyData;
  final Map<String, Object?>? _instances;
  final Map<String, String?>? _providedNames;

  /// Creates a [Dependencies] container with the provided [dependencyMapsData].
  ///
  /// [instances] and [providedNames], keyed by token representation, hold the
  /// results of one resolution. Without them, the values last written to each
  /// [Dependency] in [dependencyMapsData] are used.
  Dependencies(DependencyData dependencyMapsData, {Map<String, Object?>? instances, Map<String, String?>? providedNames})
      : _dependencyData = dependencyMapsData,
        _instances = instances,
        _providedNames = providedNames;

  /// Retrieves a dependency of type [T].
  ///
  /// This is a convenience operator for [get].
  T call<T extends Object>([Object? token]) => get<T>(token);

  /// Retrieves a dependency of type [T].
  ///
  /// * [token]: An optional token (e.g., [InjectorToken]) or [Type] to
  ///   disambiguate between different implementations of the same type.
  ///
  /// Throws an [InjectorError] if the dependency was not requested or cannot be found.
  T get<T extends Object>([Object? token]) {
    var service = getOptional<T>(token);
    if (service != null) return service;
    throw InjectorError("Requested Type or InjectorToken is null: ${_getTokenRepresentation(token)}");
  }

  /// Retrieves a dependency of type [T], or returns `null` if it cannot be found.
  ///
  /// * [token]: An optional token (e.g., [InjectorToken]) or [Type].
  T? getOptional<T extends Object>([Object? token]) {
    final tokenRepresentation = _getTokenRepresentation<T>(token);
    final instanceOrNull = _getFromTokenRepresentation<T>(tokenRepresentation);
    if (instanceOrNull == null) return null;
    try {
      return instanceOrNull as T;
    } catch (ex) {
      throw InjectorError("Dependency for \"$tokenRepresentation\" found but cast to selected type is invalid.");
    }
  }

  Object? _getFromTokenRepresentation<T extends Object>(String tokenRepresentation) {
    assert(
        _dependencyData.all.keys.contains(tokenRepresentation), "Dependency for \"$tokenRepresentation\" wasn't listed in Injector.resolveDependencies[] request.  Please add it to dependency list.");
    final instances = _instances;
    if (instances != null) return instances[tokenRepresentation];
    return _dependencyData.all[tokenRepresentation]!.instance;
  }

  Object? _instanceOf(Dependency dependency) => _instances != null ? _instances[dependency.tokenString] : dependency.instance;

  String? _parameterNameOf(Dependency dependency) {
    if (dependency.wrapperName != null || _providedNames == null) return dependency.parameterName;
    return _providedNames[dependency.tokenString];
  }

  /// Invokes [function] by mapping its arguments to the resolved dependencies.
  T invokeApply<T>(Function function) => Function.apply(
        function,
        _dependencyData.positionalSorted.map(_instanceOf).toList(),
        _dependencyData.named.map((key, value) => MapEntry(Symbol(_parameterNameOf(value)!), _instanceOf(value))),
      );

  static String _getTokenRepresentation<T extends Object>([Object? token]) {
    return InjectorToken.fromTokenOrType(token ?? T).tokenRepresentation;
  }
}
