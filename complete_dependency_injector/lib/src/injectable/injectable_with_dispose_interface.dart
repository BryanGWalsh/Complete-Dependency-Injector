import "../library_src.dart";

abstract mixin class InjectableWithDisposeInterface implements Injectable{
  Future<void> dispose();
}