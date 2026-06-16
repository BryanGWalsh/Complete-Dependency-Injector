class InjectorDebugOptions {
  final bool allowFactoryReplacement;
  final bool errorOnProviderInstanceScopeMismatch;
  final bool errorOnDuplicateScopeProviderStrategy;

  InjectorDebugOptions({this.allowFactoryReplacement = false, this.errorOnProviderInstanceScopeMismatch = true, this.errorOnDuplicateScopeProviderStrategy = true});

  InjectorDebugOptions.liveDangerously({this.allowFactoryReplacement = true, this.errorOnProviderInstanceScopeMismatch = false, this.errorOnDuplicateScopeProviderStrategy = false});

}