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

  /// A copy of this data with fresh, unresolved [Dependency] entries, so one
  /// resolution can't overwrite another's instances.
  DependencyData copyUnresolved() {
    final copies = Map<Dependency, Dependency>.identity();
    Dependency copyOf(Dependency d) => copies.putIfAbsent(d, d.copyUnresolved);
    final copy = DependencyData(safety: _safety);
    copy._setMapTypes.addAll(_setMapTypes);
    all.forEach((key, d) => copy.all[key] = copyOf(d));
    positional.forEach((key, d) => copy.positional[key] = copyOf(d));
    named.forEach((key, d) => copy.named[key] = copyOf(d));
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
