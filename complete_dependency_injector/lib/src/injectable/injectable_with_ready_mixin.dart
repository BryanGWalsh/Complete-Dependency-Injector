import 'dart:async';
import "../library_src.dart";

mixin InjectableWithReadyMixin implements InjectableWithReadyInterface, InjectableWithDisposeInterface{

  final Completer<bool> _injectableReadyCompleter = Completer();

  @override
  Future<bool> get injectableReady => _injectableReadyCompleter.future;

  void setInjectableReadyResult(bool isReady) => _injectableReadyCompleter.complete(isReady);

  @override
  Future<void> dispose(){
    return Future.value();
  }

}