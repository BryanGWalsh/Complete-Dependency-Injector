import 'dart:async';

import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

// Same factory resolved by two injectors at once.
abstract class Named {
  String get value;
}

class Delayed with InjectableWithReadyMixin implements Named {
  Delayed(this.value, int ms) {
    Future<void>.delayed(Duration(milliseconds: ms), () => setInjectableReadyResult(true));
  }
  @override
  final String value;
}

class ParentA extends Delayed {
  ParentA() : super('parentA', 10);
}

class ParentB extends Delayed {
  ParentB() : super('parentB', 40);
}

class ChildA extends Delayed {
  ChildA() : super('childA', 40);
}

class ChildB extends Delayed {
  ChildB() : super('childB', 10);
}

final tokenA = InjectorToken.fromString('async_errors_a');
final tokenB = InjectorToken.fromString('async_errors_b');

class Pair {
  Pair(this.a, this.b);
  final String a;
  final String b;
  @override
  String toString() => '$a,$b';
}

class KeepsDependencies {
  KeepsDependencies(this.dependencies);
  final Dependencies dependencies;
}

// Fails the first time it is built.
int flakyBuilds = 0;

class Flaky {
  Flaky() {
    flakyBuilds++;
    if (flakyBuilds == 1) throw StateError('transient failure');
  }
}

abstract class FlakyRole {}

class AlwaysFails implements InjectableWithDisposeInterface {
  AlwaysFails() {
    throw StateError('always fails');
  }
  @override
  Future<void> dispose() async {}
}

class Disposable implements InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

abstract class DisposableRole {}

class NotReady with InjectableWithReadyMixin {
  NotReady() {
    Future<void>.delayed(const Duration(milliseconds: 5), () => setInjectableReadyResult(false));
  }
}

class SetupFails with InjectableWithReadyMixin {
  SetupFails() {
    _init();
  }
  Future<void> _init() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      throw StateError('could not connect');
    } catch (e, s) {
      setInjectableReadyError(e, s);
    }
  }
}

class CycleA {}

class CycleB {}

class SelfCycle {}

void main() {
  setUpAll(() {
    Injector([]).registerFactories([
      InjectableFactory.withoutDependencies<ParentA>(() => ParentA()),
      InjectableFactory.withoutDependencies<ParentB>(() => ParentB()),
      InjectableFactory.withoutDependencies<ChildA>(() => ChildA()),
      InjectableFactory.withoutDependencies<ChildB>(() => ChildB()),
      InjectableFactory.withDependencies<Pair>(
        DependencyDataBuilder.list([tokenA, tokenB]),
        (deps) => Pair(deps.get<Named>(tokenA).value, deps.get<Named>(tokenB).value),
      ),
      InjectableFactory.withDependencies<KeepsDependencies>(
        DependencyDataBuilder.list([tokenA]),
        (deps) => KeepsDependencies(deps),
      ),
      InjectableFactory.withoutDependencies<Flaky>(() => Flaky()),
      InjectableFactory.withoutDependencies<AlwaysFails>(() => AlwaysFails()),
      InjectableFactory.withoutDependencies<Disposable>(() => Disposable()),
      InjectableFactory.withoutDependencies<NotReady>(() => NotReady()),
      InjectableFactory.withoutDependencies<SetupFails>(() => SetupFails()),
      InjectableFactory.withDependencies<CycleA>(DependencyDataBuilder.positional([CycleB]).done(), (_) => CycleA()),
      InjectableFactory.withDependencies<CycleB>(DependencyDataBuilder.positional([CycleA]).done(), (_) => CycleB()),
      InjectableFactory.withDependencies<SelfCycle>(DependencyDataBuilder.positional([SelfCycle]).done(), (_) => SelfCycle()),
    ]);
  });

  group('concurrent resolution', () {
    test('two scopes building the same factory at once each get their own dependencies', () async {
      final parent = Injector([
        Provider(Pair),
        Provider.factory(tokenA, fromDerived: ParentA),
        Provider.factory(tokenB, fromDerived: ParentB),
      ]);
      final child = Injector([
        Provider(Pair),
        Provider.factory(tokenA, fromDerived: ChildA),
        Provider.factory(tokenB, fromDerived: ChildB),
      ], parent: parent);

      final pairs = await Future.wait([parent.getService<Pair>(), child.getService<Pair>()]);
      expect(pairs.map((p) => '$p'), ['parentA,parentB', 'childA,childB']);
    });

    test('Dependencies kept by a service are not overwritten by a later resolution', () async {
      final parent = Injector([Provider(KeepsDependencies), Provider.value(tokenA, 'parent')]);
      final child = Injector([Provider(KeepsDependencies), Provider.value(tokenA, 'child')], parent: parent);

      final fromParent = await parent.getService<KeepsDependencies>();
      await child.getService<KeepsDependencies>();
      expect(fromParent.dependencies.get<String>(tokenA), 'parent');
    });
  });

  group('failures', () {
    test('a failed factory is retried on the next request instead of rethrowing the cached error', () async {
      flakyBuilds = 0;
      final injector = Injector([Provider(Flaky)]);
      await expectLater(injector.getService<Flaky>(), throwsStateError);
      expect(await injector.getService<Flaky>(), isA<Flaky>());
      expect(flakyBuilds, 2);
    });

    test('a retry through an alias builds the service again too', () async {
      flakyBuilds = 0;
      final injector = Injector([Provider(Flaky, aliasTokens: [FlakyRole])]);
      await expectLater(injector.getService<Flaky>(FlakyRole), throwsStateError);
      expect(await injector.getService<Flaky>(FlakyRole), isA<Flaky>());
      expect(identical(await injector.getService<Flaky>(), await injector.getService<Flaky>(FlakyRole)), isTrue);
    });

    test('dispose still succeeds, and disposes the rest, after a factory failed', () async {
      final injector = Injector([Provider(AlwaysFails), Provider(Disposable)]);
      final disposable = await injector.getService<Disposable>();
      await expectLater(injector.getService<AlwaysFails>(), throwsStateError);

      await injector.dispose();
      expect(disposable.disposeCount, 1);
    });

    test('a service with an alias is disposed once', () async {
      final injector = Injector([Provider(Disposable, aliasTokens: [DisposableRole])]);
      final disposable = await injector.getService<Disposable>(DisposableRole);
      await injector.getService<Disposable>();

      await injector.dispose();
      expect(disposable.disposeCount, 1);
    });
  });

  group('readiness', () {
    test('setInjectableReadyResult(false) fails resolution instead of handing the service out', () async {
      final injector = Injector([Provider(NotReady)]);
      await expectLater(injector.getService<NotReady>(), throwsA(isA<InjectorError>()));
    });

    test('setInjectableReadyError surfaces the setup error', () async {
      final injector = Injector([Provider(SetupFails)]);
      await expectLater(
        injector.getService<SetupFails>().timeout(const Duration(seconds: 2)),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'could not connect')),
      );
    });
  });

  group('cycles', () {
    test('a dependency cycle fails with an InjectorError instead of overflowing the stack', () async {
      final injector = Injector([Provider(CycleA), Provider(CycleB)]);
      await expectLater(
        injector.getService<CycleA>().timeout(const Duration(seconds: 2)),
        throwsA(isA<InjectorError>().having((e) => e.message, 'message', contains('Circular dependency'))),
      );
    });

    test('a service that depends on itself fails with an InjectorError', () async {
      final injector = Injector([Provider(SelfCycle)]);
      await expectLater(injector.getService<SelfCycle>(), throwsA(isA<InjectorError>()));
    });
  });
}
