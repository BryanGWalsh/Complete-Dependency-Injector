import 'dart:async';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

// --- Mock Services ---

class SyncService {
  String get name => "Sync";
}

class AsyncService implements InjectableWithReadyInterface {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Completer<bool> _completer = Completer<bool>();

  AsyncService() {
    // Simulate async work
    Future.delayed(Duration(milliseconds: 10), () {
      _initialized = true;
      _completer.complete(true);
    });
  }

  @override
  Future<bool> get injectableReady => _completer.future;
}

class MixedDependencyService {
  final SyncService sync;
  final AsyncService async;
  
  MixedDependencyService(this.sync, this.async);
  
  String get status => "Sync: ${sync.name}, Async Ready: ${async.isInitialized}";
}

class DisposableService implements InjectableWithDisposeInterface {
  bool disposed = false;
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class MixinAsyncService with InjectableWithReadyMixin {
  MixinAsyncService() {
    Future.delayed(Duration(milliseconds: 10), () {
      setInjectableReadyResult(true);
    });
  }
}

void main() {
  final debugOptions = InjectorDebugOptions(allowFactoryReplacement: true);

  group('Complex Async & Lifecycle Tests', () {
    test('InjectableWithReadyMixin waits for readiness', () async {
      final injector = Injector([
        Provider(MixinAsyncService),
      ], debugOptions: debugOptions);

      injector.registerFactory(
        InjectableFactory.withoutDependencies<MixinAsyncService>(() => MixinAsyncService()),
      );

      final service = await injector.getService<MixinAsyncService>();
      expect(await service.injectableReady, isTrue);
    });

    test('resolves mixed sync and async dependencies correctly', () async {
      final injector = Injector([
        Provider(SyncService),
        Provider(AsyncService),
        Provider(MixedDependencyService),
      ], debugOptions: debugOptions);

      injector.registerFactories([
        InjectableFactory.withoutDependencies<SyncService>(() => SyncService()),
        InjectableFactory.withoutDependencies<AsyncService>(() => AsyncService()),
        InjectableFactory.withDependencies<MixedDependencyService>(
          DependencyDataBuilder.list([SyncService, AsyncService]),
          (deps) => MixedDependencyService(deps<SyncService>(), deps<AsyncService>()),
        ),
      ]);

      final mixed = await injector.getService<MixedDependencyService>();
      
      // Ensure the async service was actually ready before the mixed service was created
      expect(mixed.status, "Sync: Sync, Async Ready: true");
    });

    test('onReady waits for internal async initialization', () async {
      final injector = Injector([
        Provider(AsyncService),
      ], debugOptions: debugOptions);

      injector.registerFactory(
        InjectableFactory.withoutDependencies<AsyncService>(() => AsyncService()),
      );

      final service = await injector.getService<AsyncService>();
      expect(service.isInitialized, isTrue);
    });

    test('disposal propagates through scopes', () async {
      final disposable = DisposableService();
      final injector = Injector([
        Provider.value(DisposableService, disposable),
      ], debugOptions: debugOptions);
      
      // Request service to ensure it is tracked
      await injector.getService<DisposableService>();

      // Create a child scope
      final childDisposable = DisposableService();
      final childInjector = Injector([
        Provider.value(DisposableService, childDisposable),
      ], parent: injector);
      
      // Request service to ensure it is tracked
      await childInjector.getService<DisposableService>();

      await childInjector.dispose();
      
      expect(childDisposable.disposed, isTrue);
      expect(disposable.disposed, isFalse, reason: "Parent should not be disposed by child disposal");
      
      await injector.dispose();
      expect(disposable.disposed, isTrue);
    });
  });

  group('Deep Scope Tests', () {
    test('resolves through 3 levels of nesting', () async {
      final root = Injector([Provider.value(String, "Root")], debugOptions: debugOptions);
      final mid = Injector([Provider.value(int, 100)], parent: root);
      final bottom = Injector([Provider.value(double, 1.5)], parent: mid);

      expect(await bottom.getService<String>(), "Root");
      expect(await bottom.getService<int>(), 100);
      expect(await bottom.getService<double>(), 1.5);
    });
  });
}
