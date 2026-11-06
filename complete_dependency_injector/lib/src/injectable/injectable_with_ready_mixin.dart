import 'dart:async';
import "../library_src.dart";

mixin InjectableWithReadyMixin implements InjectableWithReadyInterface, InjectableWithDisposeInterface{

  final Completer<bool> _injectableReadyCompleter = Completer();

  @override
  Future<bool> get injectableReady => _injectableReadyCompleter.future;

  /// Reports whether setup succeeded. `false` makes resolving this service
  /// fail with an [InjectorError].
  void setInjectableReadyResult(bool isReady) => _injectableReadyCompleter.complete(isReady);

  /// Reports that setup failed with [error]. Resolving this service, and
  /// anything that depends on it, fails with [error].
  void setInjectableReadyError(Object error, [StackTrace? stackTrace]) => _injectableReadyCompleter.completeError(error, stackTrace);

  @override
  Future<void> dispose(){
    return Future.value();
  }

}