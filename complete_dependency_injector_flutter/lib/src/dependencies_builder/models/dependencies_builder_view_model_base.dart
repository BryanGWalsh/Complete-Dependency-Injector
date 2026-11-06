import "package:flutter/foundation.dart";
import "package:complete_dependency_injector/complete_dependency_injector.dart";
import "../../lib_internal_main.dart";

abstract class DependencyBuilderViewModelBase {
  // internal properties
  bool _propertiesFormDependencyDataInjectedDependenciesSet = false;
  // Set when setPropertiesOnDependencyResolution threw. The dependencies don't
  // change, so retrying would fail the same way: stay in the error state.
  bool _setPropertiesFailed = false;

  // readonly properties 
  bool _error = false;
  bool get error => _error;

  DependenciesBuilderViewModelStates _state = DependenciesBuilderViewModelStates.newNotInitialized;
  DependenciesBuilderViewModelStates get state => _state;

  // Note realize this can be simplified slight by using: "DependencyData" class here as opposed to List<object> for simplification but...
  // Rather have them use "DependencyDataBuilder.list" function in the code where they are creating the view model so if error happens it happens in view model constructor code then in shared library code making it easier to debug.
  final DependencyData _dependencyDataList;
  DependencyData get dependencyDataList => _dependencyDataList;
  
  // Projected properties to get ready or loading state instead of having to inspect individual `state` properties
  bool get ready => _state == DependenciesBuilderViewModelStates.readyForConsumption;
  bool get loading => _state != DependenciesBuilderViewModelStates.generalError && _state != DependenciesBuilderViewModelStates.readyForConsumption;

  DependencyBuilderViewModelBase({
    required DependencyData dependencyDataList,
  })  : _dependencyDataList = dependencyDataList;

  void updateFromAsyncDependenciesDataChange(bool hasError, [Dependencies? dependencies, List<dynamic>? streamSnapshots]) {
    if (_setPropertiesFailed) {
      _error = true;
      _state = DependenciesBuilderViewModelStates.generalError;
      return;
    }
    _state = DependenciesBuilderViewModelStates.resolvingDependencies;
    // Cleared on every update, so the flag recovers once a stream emits again.
    _error = hasError;
    if (hasError) {
      _error = true;
      _state = DependenciesBuilderViewModelStates.generalError;
      return;
    }
    if (dependencies == null){
      _state = DependenciesBuilderViewModelStates.resolvedDependencies;
      return;
    }
    if(_propertiesFormDependencyDataInjectedDependenciesSet == false){
      try {
        setPropertiesOnDependencyResolution(dependencies);
      } catch (error, stackTrace) {
        // Stay in the error state rather than reporting ready with properties
        // that were never set.
        _setPropertiesFailed = true;
        _error = true;
        _state = DependenciesBuilderViewModelStates.generalError;
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'complete_dependency_injector_flutter',
          context: ErrorDescription('while running setPropertiesOnDependencyResolution on $runtimeType'),
        ));
        return;
      }
      _propertiesFormDependencyDataInjectedDependenciesSet = true;
      _state = DependenciesBuilderViewModelStates.waitingForInitialStreamSnapshots;
    }
    if (streamSnapshots == null) return;
    updateViewModelPropertiesOnStreamEmission(streamSnapshots);
    _state = DependenciesBuilderViewModelStates.readyForConsumption;
  }

  // 1. Below function implemented in derived class - gets injectable services/values from dependency container and sets properties on derived class to hold them
  void setPropertiesOnDependencyResolution(Dependencies dependenciesContainer);
  // 2. Below function implemented in derived class - returns list of streams to observe for `updateViewModelPropertiesOnStreamEmission()`
  Iterable<Stream<dynamic>> getListOfStreamsToObserve();
  // 3. Below function implemented in derived class - gets streams from list index and sets to derived class properties
  void updateViewModelPropertiesOnStreamEmission(List<dynamic> streamSnapshotList);
}