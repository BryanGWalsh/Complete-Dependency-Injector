class ProvideStrategy {
  final String provides;
  final String? useExisting;
  final Object? useValue;
  final String? name = null;
  
  bool get shouldHaveFactory => useValue == null && useExisting == null;
  ProvideStrategy({required this.provides, this.useExisting, this.useValue});
}
