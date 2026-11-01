enum DependenciesBuilderViewModelStates{
  newNotInitialized,
  resolvingDependencies,
  resolvedDependencies,
  waitingForInitialStreamSnapshots,
  readyForConsumption,
  generalError,
  /*
  DependencyResolutionError,
  StreamProjectionFunctionError,
  IndividualStreamInCombineLatestThrewError,
  */
}