import 'dart:async';

import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

const _t = Timeout(Duration(seconds: 5));

class Counted implements InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

abstract class Base {}

class Impl implements Base, InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

class AliasA {}

class Aliased implements InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

class Failing {}

class Healthy implements InjectableWithDisposeInterface {
  bool disposed = false;
  @override
  Future<void> dispose() async => disposed = true;
}

class AfterDispose implements InjectableWithDisposeInterface {
  bool disposed = false;
  @override
  Future<void> dispose() async => disposed = true;
}

class NeverReady with InjectableWithReadyMixin {}

class ValueService implements InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

class NeedsInjector {
  final Injector injector;
  NeedsInjector(this.injector);
}

void main() {
  final setup = Injector([]);
  setup.registerFactories([
    InjectableFactory.withoutDependencies<Impl>(() => Impl()),
    InjectableFactory.withoutDependencies<Counted2>(() => Counted2()),
    InjectableFactory.withoutDependencies<Aliased>(() => Aliased()),
    InjectableFactory.withoutDependencies<Failing>(() => throw StateError('boom')),
    InjectableFactory.withoutDependencies<Healthy>(() => Healthy()),
    InjectableFactory.withoutDependencies<AfterDispose>(() => AfterDispose()),
    InjectableFactory.withoutDependencies<NeverReady>(() => NeverReady()),
    InjectableFactory.withDependencies<NeedsInjector>(
      DependencyDataBuilder.positional([Injector]).done(),
      (d) => NeedsInjector(d<Injector>()),
    ),
  ]);

  test('fixed: fromDerived instance is disposed twice (Base + Impl entries)', () async {
    final injector = Injector([Provider.factory(Base, fromDerived: Impl)]);
    final s = await injector.getService<Base>() as Impl;
    await injector.dispose();
    expect(s.disposeCount, 1);
  }, timeout: _t);

  test('fixed: aliased instance is disposed once per alias token', () async {
    final injector = Injector([Provider.factory(Aliased, aliasTokens: [AliasA])]);
    final s = await injector.getService<Aliased>();
    await injector.getService<Aliased>(AliasA);
    await injector.dispose();
    expect(s.disposeCount, 1);
  }, timeout: _t);

  test('fixed: Injector token cannot be resolved as a dependency', () async {
    final injector = Injector([Provider.factory(NeedsInjector)]);
    final s = await injector.getService<NeedsInjector>();
    expect(identical(s.injector, injector), isTrue);
  }, timeout: _t);

  test('fixed: Injector token getService<Injector>()', () async {
    final injector = Injector([]);
    expect(identical(await injector.getService<Injector>(), injector), isTrue);
  }, timeout: _t);

  test('fixed: explicitly providing the Injector returns the resolver instead', () async {
    final injector = Injector([]);
    final child = Injector([Provider.value(Injector, injector)], parent: injector);
    expect(await child.getService<Injector>(), same(injector));
  }, timeout: _t);

  test('fixed: one failed factory makes dispose throw (and earlier failure resurfaces)', () async {
    final injector = Injector([Provider.factory(Failing), Provider.factory(Healthy)]);
    final h = await injector.getService<Healthy>();
    await expectLater(injector.getService<Failing>(), throwsStateError);
    Object? disposeError;
    try {
      await injector.dispose();
    } catch (e) {
      disposeError = e;
    }
    expect(h.disposed, isTrue, reason: 'other instances still disposed');
    expect(disposeError, isNull, reason: 'dispose rethrew the old creation error');
  }, timeout: _t);

  test('fixed: disposing twice disposes instances twice', () async {
    final injector = Injector([Provider.factory(Impl)]);
    final s = await injector.getService<Impl>();
    await injector.dispose();
    await injector.dispose();
    expect(s.disposeCount, 1);
  }, timeout: _t);

  test('fixed: using an injector after dispose hands out disposed instances', () async {
    final injector = Injector([Provider.factory(AfterDispose)]);
    final s = await injector.getService<AfterDispose>();
    await injector.dispose();
    Object? result;
    try {
      result = await injector.getService<AfterDispose>();
    } catch (e) {
      result = e;
    }
    expect(result, isNot(same(s)), reason: 'returned the already-disposed instance');
    expect(s.disposed, isTrue);
  }, timeout: _t);

  test('fixed: dispose hangs if a service never becomes ready', () async {
    final injector = Injector([Provider.factory(NeverReady)]);
    unawaited(injector.getService<NeverReady>());
    await injector.dispose().timeout(const Duration(seconds: 1));
  }, timeout: _t);


  test('fixed: disposing parent does not dispose child (childResolvers never populated)', () async {
    final parent = Injector([]);
    final child = Injector([Provider.factory(Counted2)], parent: parent);
    final s = await child.getService<Counted2>();
    await parent.dispose();
    expect(s.disposed, isTrue);
  }, timeout: _t);
}

class Counted2 implements InjectableWithDisposeInterface {
  bool disposed = false;
  @override
  Future<void> dispose() async => disposed = true;
}
