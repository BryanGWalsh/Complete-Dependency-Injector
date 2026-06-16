import '../library_src.dart';
import 'provide_strategy.dart';

/// Defines how a dependency is provided within an [Injector].
///
/// A [Provider] maps a token to a value, an existing dependency, or a factory.
class Provider {
  final String _provide;
  final Iterable<String> _aliases;
  final String? _fromExisting;
  final String? _factory;
  final Object? _value;

  /// The primary token used to identify this dependency.
  String get primaryToken => _provide;

  /// Returns the strategies derived from this provider configuration.
  Iterable<ProvideStrategy> get strategies => [
        if (_factory != null) ...[
          ProvideStrategy(provides: _factory),
          if (_provide != _factory) ProvideStrategy(provides: _provide, useExisting: _factory)
        ],
        if (_fromExisting != null) ProvideStrategy(provides: _provide, useExisting: _fromExisting),
        if (_value != null) ProvideStrategy(provides: _provide, useValue: _value),
        ..._aliases.map((alias) => ProvideStrategy(provides: alias, useExisting: _provide)),
      ];

  /// Internal constructor for creating a [Provider].
  ///
  /// Prefer using the factory constructors like [Provider.value], [Provider.existing],
  /// or [Provider.factory] for better readability.
  Provider(Object token, {List<Object>? aliasTokens, Object? fromExisting, Object? fromDerived, Object? fromValue})
      : assert([fromExisting, fromValue, fromDerived].where((e) => e != null).length < 2,
            "Provide: ${_objectToTokenString(token)}: fromExisting, fromDerived, and fromValue are mutually exclusive"),
        _provide = _objectToTokenString(token)!,
        _value = fromValue,
        _fromExisting = _objectToTokenString(fromExisting),
        _factory = _getFactoryString(token, fromExisting, fromDerived, fromValue),
        _aliases = aliasTokens == null ? [] : aliasTokens.map((e) => _objectToTokenString(e)!);

  /// Provides a dependency as a constant value.
  ///
  /// * [token]: The token to associate with this value.
  /// * [value]: The actual object instance to provide.
  /// * [aliasTokens]: Optional additional tokens that can be used to retrieve this value.
  factory Provider.value(Object token, Object value, {List<Object>? aliasTokens}) =>
      Provider(token, fromValue: value, aliasTokens: aliasTokens);

  /// Provides a dependency by delegating to another existing dependency.
  ///
  /// * [token]: The new token to define.
  /// * [existing]: The existing token to delegate to.
  /// * [aliasTokens]: Optional additional tokens.
  factory Provider.existing(Object token, Object existing, {List<Object>? aliasTokens}) =>
      Provider(token, fromExisting: existing, aliasTokens: aliasTokens);

  /// Provides a dependency using a factory.
  ///
  /// * [token]: The token associated with the created object.
  /// * [fromDerived]: Optional. If provided, the factory will be used for this
  ///   derived type.
  /// * [aliasTokens]: Optional additional tokens.
  factory Provider.factory(Object token, {Object? fromDerived, List<Object>? aliasTokens}) =>
      Provider(token, fromDerived: fromDerived, aliasTokens: aliasTokens);

  static String? _getFactoryString(Object token, Object? fromExisting, Object? fromDerived, Object? fromValue) {
    if (fromValue != null || fromExisting != null) return null;
    return _objectToTokenString(fromDerived ?? token);
  }

  static String? _objectToTokenString(Object? obj) {
    if (obj == null) return null;
    if (obj is InjectorToken) return obj.tokenRepresentation;
    return InjectorToken.fromType(obj as Type).tokenRepresentation;
  }
}
