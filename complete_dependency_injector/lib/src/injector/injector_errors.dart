class InjectorError extends Error {
  final String message;
  InjectorError(this.message);

  @override
  String toString() => 'InjectorError: $message';
}
