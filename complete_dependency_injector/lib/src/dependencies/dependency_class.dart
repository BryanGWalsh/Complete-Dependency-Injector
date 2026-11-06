import '../library_src.dart';

class Dependency{
  final String tokenString;
  final bool optional;
  final String? wrapperName;
  final bool positionalOnly;
  int index = 0;
  String? providedName;
  Object? instance;
  bool get maybeNamed => !positionalOnly && parameterName != null;
  String? get parameterName => wrapperName ?? providedName;
  Dependency._(this.tokenString, {this.optional = false, String? name, bool? positionalOnly}) : wrapperName = name, positionalOnly = positionalOnly ?? false;
  Dependency.named(Object tokenOrType, String name) : this._(InjectorToken.fromTokenOrType(tokenOrType).tokenRepresentation, optional: false, name: name);
  Dependency.namedOptional(Object tokenOrType, String name): this._(InjectorToken.fromTokenOrType(tokenOrType).tokenRepresentation, optional: true, name: name);
  Dependency.positional(Object tokenOrType) : this._(InjectorToken.fromTokenOrType(tokenOrType).tokenRepresentation, optional: false, positionalOnly: true);
  Dependency.positionalOptional(Object tokenOrType) : this._(InjectorToken.fromTokenOrType(tokenOrType).tokenRepresentation, optional: true, positionalOnly: true);

  /// A copy of this request with no resolved instance, so one resolution
  /// never sees or overwrites another's results.
  Dependency copyUnresolved() => Dependency._(tokenString, optional: optional, name: wrapperName, positionalOnly: positionalOnly)..index = index;
}
