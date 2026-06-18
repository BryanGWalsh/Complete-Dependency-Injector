import '../library_src.dart';
import 'dependency_class.dart';
class DependencyListBuilderDependencyMapsUtil {

  final DependencyData data;
  final bool _safety;
  DependencyListBuilderDependencyMapsUtil({safety = true}) : data = DependencyData(safety: safety), _safety = safety;

  void _addToMap(Iterable<Dependency> dependencies, DependencyMapType type) {
    data.safeToSetOrError(type);
    Map<String, Dependency> targetMap;
    String addTypeErrorMessage;
    switch (type) {
      case DependencyMapType.positional:
      targetMap = data.positional;
      addTypeErrorMessage = "Positional dependency list already contains entry for ";
      case DependencyMapType.namedRequired:
      targetMap = data.named;
      addTypeErrorMessage = "Named dependency list already contains entry for ";
      case DependencyMapType.namedOptional:
      targetMap = data.named;
      addTypeErrorMessage = "Named dependency list already contains entry for ";
    }
    final map = dependencies.toTokenMap();
    if(_safety){
      targetMap.addAllSafe(map, addTypeErrorMessage);
      data.all.addAllSafe(map, "Positional or Named dependency was already added for ");
      return;
    }
    targetMap.addAll(map);
    data.all.addAll(map);
  }

  void addNamedOptional(Iterable<Dependency> dependencies) => _addToMap(dependencies, DependencyMapType.namedOptional);
  void addNamedRequired(Iterable<Dependency> dependencies) => _addToMap(dependencies, DependencyMapType.namedRequired);
  void addPositional(Iterable<Dependency> dependencies) => _addToMap(dependencies, DependencyMapType.positional);
}



typedef DependencyMap = Map<String, Dependency>;
extension _DependencyListToTokenStringDependencyMap on Iterable<Dependency>{
  Map<String, Dependency> toTokenMap() => Map.fromEntries(map((e) => MapEntry(e.tokenString, e)));
}
extension _DependencyTokenStringDependencyMapSafeAddAll on Map<String, Dependency>{
  void addAllSafe(Map<String, Dependency> other, [String? errorMessageParam]) {
    final errorMessage = errorMessageParam ?? "Dependency already exists";
    other.forEach((key, value) {
      if (containsKey(key)) throw InjectorError(errorMessage + key);
      this[key] = value;
    });
  }
}