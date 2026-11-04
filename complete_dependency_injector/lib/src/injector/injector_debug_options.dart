/// Controls how strict an [Injector] is about its configuration.
class InjectorDebugOptions {
  /// Allow registering a second factory for a type that already has one.
  final bool allowFactoryReplacement;

  /// Throw when an injector's providers define the same token more than once.
  final bool errorOnDuplicateScopeProviderStrategy;

  InjectorDebugOptions({this.allowFactoryReplacement = false, this.errorOnDuplicateScopeProviderStrategy = true});

  InjectorDebugOptions.liveDangerously({this.allowFactoryReplacement = true, this.errorOnDuplicateScopeProviderStrategy = false});
}
