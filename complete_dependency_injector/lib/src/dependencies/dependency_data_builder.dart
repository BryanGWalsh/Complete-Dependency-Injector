import "../library_src.dart";
import 'dependency_class.dart';
import 'dependency_data_builder_dependency_maps_util.dart';

class DependencyDataBuilder {
  final DependencyListBuilderDependencyMapsUtil mapsUtil;

  DependencyDataBuilder({
    Iterable<Object>? positional,
    Map<String, Object>? namedRequired,
    Map<String, Object>? namedOptional,
    Iterable<Object>? list,
    bool safety = true,
  }) : mapsUtil = DependencyListBuilderDependencyMapsUtil(safety: safety) {
    if (positional != null) this.positional(positional);
    if (namedRequired != null) this.namedRequired(namedRequired);
    if (namedOptional != null) this.namedOptional(namedOptional);
    if (list != null) _list(list);
  }

  DependencyDataBuilder _list(Iterable<Object> list) {
    mapsUtil.addPositional(list.toDependencyList((Dependency.positionalOptional)));
    return this;
  }

  DependencyDataBuilder positional(Iterable<Object> list) {
    mapsUtil.addPositional(list.toDependencyList((Dependency.positional)));
    return this;
  }

  DependencyDataBuilder named({Map<String, Object>? required, Map<String, Object>? optional}) {
    assert(required != null || optional != null, "DependencyDataBuilder.named must be called with required or optional object maps");
    if (required != null) namedRequired(required);
    if (optional != null) namedOptional(optional);
    return this;
  }

  DependencyDataBuilder namedRequired(Map<String, Object> map) {
    mapsUtil.addNamedRequired(map.toDependencyList(Dependency.named));
    return this;
  }

  DependencyDataBuilder namedOptional(Map<String, Object> map) {
    mapsUtil.addNamedOptional(map.toDependencyList(Dependency.namedOptional));
    return this;
  }

  DependencyData done() => mapsUtil.data;

  factory DependencyDataBuilder.positional(List<Object> list, {safety = true}) => DependencyDataBuilder(positional: list, safety: safety);

  factory DependencyDataBuilder.namedRequired(Map<String, Object> map, {safety = true}) => DependencyDataBuilder(namedRequired: map, safety: safety);

  factory DependencyDataBuilder.named({
    Map<String, Object>? required,
    Map<String, Object>? optional,
    safety = true,
  }) =>
      DependencyDataBuilder(
        namedRequired: required,
        namedOptional: optional,
        safety: safety,
      );

  factory DependencyDataBuilder.namedOptional(Map<String, Object> map, {safety = true}) => DependencyDataBuilder(namedOptional: map, safety: safety);
  static DependencyData empty = DependencyDataBuilder(safety: true).done();
  static DependencyData emptyWithoutSafety = DependencyDataBuilder(safety: false).done();

  static DependencyData list(List<Object> list, {safety = true}) => DependencyDataBuilder(list: list, safety: safety).done();
}

extension _RawDependencyListConverter on Iterable<Object> {
  Iterable<Dependency> toDependencyList(ObjectToDependencyMapItemWrapperConverter objConverter) {
    int i = 0;
    return map((e) {
      final d = e is Dependency ? e : objConverter(e);
      d.index = i++;
      return d;
    });
  }
}

extension _RawDependencyMapConverter on Map<String, Object> {
  Iterable<Dependency> toDependencyList(ObjectToNamedDependencyMapItemWrapperConverter objConverter) =>
      map((key, value) => MapEntry(key, value is Dependency ? value : objConverter(value, key))).values;
}

typedef ObjectToDependencyMapItemWrapperConverter = Dependency Function(Object obj);
typedef ObjectToNamedDependencyMapItemWrapperConverter = Dependency Function(Object obj, String name);
