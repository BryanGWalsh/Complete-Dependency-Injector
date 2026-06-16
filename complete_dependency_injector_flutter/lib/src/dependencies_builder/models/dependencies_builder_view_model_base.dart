import "package:complete_dependency_injector/complete_dependency_injector.dart";
import "../../lib_internal_main.dart";

abstract class DependencyBuilderViewModelBase {
  // internal properties
  bool _propertiesFormDependencyDataInjectedDependenciesSet = false;

  // readonly properties 
  bool _error = false;
  bool get error => _error;

  DependenciesBuilderViewModelStates _state = DependenciesBuilderViewModelStates.NewNotInitialized;
  DependenciesBuilderViewModelStates get state => _state;

  // Note realize this can be simplified slight by using: "DependencyData" class here as opposed to List<object> for simplification but...
  // Rather have them use "DependencyDataBuilder.list" function in the code where they are creating the view model so if error happens it happens in view model constructor code then in shared library code making it easier to debug.
  final DependencyData _dependencyDataList;
  DependencyData get dependencyDataList => _dependencyDataList;
  
  // Projected properties to get ready or loading state instead of having to inspect individual `state` properties
  bool get ready => _state == DependenciesBuilderViewModelStates.ReadyForConsumption;
  bool get loading => _state != DependenciesBuilderViewModelStates.GeneralError && _state != DependenciesBuilderViewModelStates.ReadyForConsumption;

  DependencyBuilderViewModelBase({
    required DependencyData dependencyDataList,
  })  : _dependencyDataList = dependencyDataList;

  updateFromAsyncDependenciesDataChange(bool hasError, [Dependencies? dependencies, List<dynamic>? streamSnapshots]) {
    _state = DependenciesBuilderViewModelStates.ResolvingDependencies;
    if (hasError) {
      _error = true;
      _state = DependenciesBuilderViewModelStates.GeneralError;
      return;
    }
    if (dependencies == null){
      _state = DependenciesBuilderViewModelStates.ResolvedDependencies;
      return;
    }
    if(_propertiesFormDependencyDataInjectedDependenciesSet == false){
      _propertiesFormDependencyDataInjectedDependenciesSet = true;
      setPropertiesOnDependencyResolution(dependencies);
      _state = DependenciesBuilderViewModelStates.WaitingForInitialStreamSnapshots;
    }
    if (streamSnapshots == null) return;
    updateViewModelPropertiesOnStreamEmission(streamSnapshots);
    _state = DependenciesBuilderViewModelStates.ReadyForConsumption;
  }

  // 1. Below function implemented in derived class - gets injectable services/values from dependency container and sets properties on derived class to hold them
  setPropertiesOnDependencyResolution(Dependencies dependenciesContainer);
  // 2. Below function implemented in derived class - returns list of streams to observe for `updateViewModelPropertiesOnStreamEmission()`
  Iterable<Stream<dynamic>> getListOfStreamsToObserve();
  // 3. Below function implemented in derived class - gets streams from list index and sets to derived class properties
  updateViewModelPropertiesOnStreamEmission(List<dynamic> streamSnapshotList);
}