enum DependenciesBuilderViewModelStates{
  NewNotInitialized,
  ResolvingDependencies,
  ResolvedDependencies,
  WaitingForInitialStreamSnapshots,
  ReadyForConsumption,
  GeneralError,
  /*
  DependencyResolutionError,
  StreamProjectionFunctionError,
  IndividualStreamInCombineLatestThrewError,
  */
}