import "../library_src.dart";
abstract class InjectableWithReadyInterface implements Injectable{
  Future<bool> get injectableReady;
}