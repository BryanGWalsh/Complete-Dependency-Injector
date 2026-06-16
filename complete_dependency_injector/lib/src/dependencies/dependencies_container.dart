import '../library_src.dart';
import 'dependency_class.dart';

/// A container for resolved dependencies.
/// When
/// This class provides methods to retrieve specific dependencies by type or token.
class Dependencies {
  final DependencyData _dependencyData;

  /// Creates a [Dependencies] container with the provided [dependencyMapsData].
  Dependencies(DependencyData dependencyMapsData) : _dependencyData = dependencyMapsData;

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
    return _dependencyData.all[tokenRepresentation]!.instance;
  }

  /// Invokes [function] by mapping its arguments to the resolved dependencies.
  T invokeApply<T>(Function function) => Function.apply(function, _dependencyData.getPositionalInstances(), _dependencyData.getNamedInstances());

  static String _getTokenRepresentation<T extends Object>([Object? token]) {
    return InjectorToken.fromTokenOrType(token ?? T).tokenRepresentation;
  }
}

extension _DependencyDataExtensions on DependencyData {
  List<Object?> getPositionalInstances() => positionalSorted.toInstanceList();

  Map<Symbol, dynamic> getNamedInstances() => named.map((key, value) => MapEntry(Symbol(value.parameterName!), value.instance));
}

extension _RawDependencyListConverter on Iterable<Dependency> {
  List<Object?> toInstanceList() => map((e) => e.instance).toList();
}
