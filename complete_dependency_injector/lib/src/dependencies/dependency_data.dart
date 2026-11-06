import '../library_src.dart';
import 'dependency_class.dart';

class DependencyData {
  final bool _safety;
  final List<DependencyMapType> _setMapTypes = [];
  final Map<String, Dependency> all = {};
  final Map<String, Dependency> positional = {};
  final Map<String, Dependency> named = {};

  bool get hasContents => all.isNotEmpty;

  bool get hasPositional => positional.isNotEmpty;

  bool get hasNamed => named.isNotEmpty;
  List<Dependency>? _positionalSorted;

  Iterable<Dependency> get positionalSorted {
    if (_positionalSorted != null) return _positionalSorted!;
    _positionalSorted = positional.values.toList();
    _positionalSorted!.sort((a, b) => a.index.compareTo(b.index));
    return _positionalSorted!;
  }

  DependencyData({bool safety = true}) : _safety = safety;

  /// A copy with fresh, unresolved [Dependency] entries.
  ///
  /// The injector resolves into a copy so that the same [DependencyData]
  /// (for example a factory's) can be resolved by several injectors at once.
  DependencyData copyUnresolved() {
    final copy = DependencyData(safety: _safety);
    copy._setMapTypes.addAll(_setMapTypes);
    final clones = <Dependency, Dependency>{};
    Dependency cloneOf(Dependency d) => clones.putIfAbsent(d, d.copyUnresolved);
    all.forEach((key, value) => copy.all[key] = cloneOf(value));
    positional.forEach((key, value) => copy.positional[key] = cloneOf(value));
    named.forEach((key, value) => copy.named[key] = cloneOf(value));
    return copy;
  }

  bool isSet(DependencyMapType type) => _setMapTypes.contains(type);

  void safeToSetOrError(DependencyMapType type) {
    if (!isSet(type)) return _setMapTypes.add(type);
    if (!_safety) return;
    throw InjectorError("Dependency list $type already set!");
  }
}

enum DependencyMapType {
  positional,
  namedRequired,
  namedOptional,
}
