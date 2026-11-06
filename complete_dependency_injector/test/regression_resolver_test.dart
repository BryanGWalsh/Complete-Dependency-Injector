import 'dart:async';

import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

const _t = Duration(seconds: 2);

// --- race on shared DependencyData ---
class Cfg {
  Cfg(this.v);
  final String v;
}

class UsesCfg {
  UsesCfg(this.cfg);
  final Cfg cfg;
}

final delayToken = InjectorToken.fromString('review_delay');

class Slow with InjectableWithReadyMixin {
  Slow(Duration d) {
    Future<void>.delayed(d, () => setInjectableReadyResult(true));
  }
}

class UsesCfgAndSlow {
  UsesCfgAndSlow(this.cfg);
  final Cfg cfg;
}

// --- double dispose ---
abstract class RoleA {}

abstract class RoleB {}

class Disposable implements RoleA, RoleB, InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

abstract class IDisp {}

class Disposable2 implements IDisp, InjectableWithDisposeInterface {
  int disposeCount = 0;
  @override
  Future<void> dispose() async => disposeCount++;
}

// --- failing factory + dispose ---
class Exploding {}

// --- ready ---
class NeverReady with InjectableWithReadyMixin {}

class NotReady with InjectableWithReadyMixin {
  NotReady() {
    scheduleMicrotask(() => setInjectableReadyResult(false));
  }
}

// --- aliases / optional ---
abstract class AliasTarget {}

abstract class AliasOnly {}

class Unbuildable {}

// --- fromDerived collision ---
abstract class IFoo {}

class Foo implements IFoo {}

// --- token subclass ---
class MyToken extends InjectorToken {
  MyToken() : super.fromString('mine');
}

// --- alias cycle ---
abstract class CycA {}

abstract class CycB {}

void main() {
  setUpAll(() {
    Injector([]).registerFactories([
      InjectableFactory.withDependencies<UsesCfg>(
        DependencyDataBuilder.list([Cfg]),
        (d) => UsesCfg(d.get<Cfg>()),
      ),
      InjectableFactory.withDependencies<Slow>(
        DependencyDataBuilder.list([delayToken]),
        (d) => Slow(d.get<Duration>(delayToken)),
      ),
      InjectableFactory.withDependencies<UsesCfgAndSlow>(
        DependencyDataBuilder.list([Cfg, Slow]),
        (d) => UsesCfgAndSlow(d.get<Cfg>()),
      ),
      InjectableFactory.withoutDependencies<Disposable>(() => Disposable()),
      InjectableFactory.withoutDependencies<Disposable2>(() => Disposable2()),
      InjectableFactory.withoutDependencies<Exploding>(() => throw StateError('boom')),
      InjectableFactory.withoutDependencies<NeverReady>(() => NeverReady()),
      InjectableFactory.withoutDependencies<NotReady>(() => NotReady()),
      InjectableFactory.withoutDependencies<Foo>(() => Foo()),
    ]);
  });

  test('fixed: control (passes): one-dependency concurrent build is not affected', () async {
    final root = Injector([]);
    final a = Injector([Provider(UsesCfg), Provider.value(Cfg, Cfg('a'))], parent: root);
    final b = Injector([Provider(UsesCfg), Provider.value(Cfg, Cfg('b'))], parent: root);
    final results = await Future.wait([a.getService<UsesCfg>(), b.getService<UsesCfg>()]).timeout(_t);
    expect(results[0].cfg.v, 'a');
    expect(results[1].cfg.v, 'b');
  });

  test('fixed: shared DependencyData is overwritten when two injectors build the same type', () async {
    final root = Injector([]);
    final a = Injector([
      Provider(UsesCfgAndSlow), Provider(Slow),
      Provider.value(Cfg, Cfg('a')), Provider.value(delayToken, const Duration(milliseconds: 50)),
    ], parent: root);
    final b = Injector([
      Provider(UsesCfgAndSlow), Provider(Slow),
      Provider.value(Cfg, Cfg('b')), Provider.value(delayToken, const Duration(milliseconds: 10)),
    ], parent: root);
    final fa = a.getService<UsesCfgAndSlow>();
    final fb = b.getService<UsesCfgAndSlow>();
    expect((await fb.timeout(_t)).cfg.v, 'b');
    expect((await fa.timeout(_t)).cfg.v, 'a');
  });

  test('fixed: aliasTokens instance is disposed once per token', () async {
    final injector = Injector([Provider.factory(Disposable, aliasTokens: [RoleA, RoleB])]);
    final x = await injector.getService<RoleA>();
    await injector.getService<RoleB>();
    await injector.dispose().timeout(_t);
    expect((x as Disposable).disposeCount, 1);
  });

  test('fixed: fromDerived instance is disposed twice', () async {
    final injector = Injector([Provider.factory(IDisp, fromDerived: Disposable2)]);
    final x = await injector.getService<IDisp>();
    await injector.dispose().timeout(_t);
    expect((x as Disposable2).disposeCount, 1);
  });

  test('fixed: dispose() rethrows an earlier factory failure', () async {
    final injector = Injector([Provider(Exploding)]);
    await expectLater(injector.getService<Exploding>(), throwsA(isA<StateError>()));
    await expectLater(injector.dispose().timeout(_t), completes);
  });

  test('fixed: dispose() never completes while a service is not ready', () async {
    final injector = Injector([Provider(NeverReady)]);
    unawaited(injector.getService<NeverReady>());
    await Future<void>.delayed(Duration.zero);
    await expectLater(injector.dispose().timeout(_t), completes);
  });

  test('fixed: setInjectableReadyResult(false) still hands the service out', () async {
    final injector = Injector([Provider(NotReady)]);
    await expectLater(injector.getService<NotReady>().timeout(_t), throwsA(anything));
  });

  test('fixed: optional request for a dangling alias caches null and poisons later required requests', () async {
    final injector = Injector([Provider.existing(AliasOnly, AliasTarget)]);
    expect(await injector.getServiceOrNull<AliasOnly>().timeout(_t), isNull);
    await expectLater(injector.getService<AliasOnly>().timeout(_t), throwsA(isA<InjectorError>()));
  });

  test('fixed: getServiceOrNull throws when the type is provided but has no factory', () async {
    final injector = Injector([Provider(Unbuildable)]);
    expect(await injector.getServiceOrNull<Unbuildable>().timeout(_t), isNull);
  });

  test('fixed: InjectorError.toString hides the message', () {
    expect(InjectorError('No provider found for X').toString(), contains('No provider found'));
  });

  test('fixed: no-factory error message does not mention the missing factory', () async {
    final injector = Injector([Provider(Unbuildable)]);
    await expectLater(
      injector.getService<Unbuildable>(),
      throwsA(isA<InjectorError>().having((e) => e.message, 'message', contains('actory'))),
    );
  });

  test('fixed: DependencyDataBuilder.named(required:) alone trips the assert', () {
    expect(() => DependencyDataBuilder().named(required: {'cfg': Cfg}), returnsNormally);
  });

  test('fixed: Provider(Foo) + Provider.factory(IFoo, fromDerived: Foo) is rejected as a duplicate', () async {
    final injector = Injector([Provider(Foo), Provider.factory(IFoo, fromDerived: Foo)]);
    expect(identical(await injector.getService<IFoo>(), await injector.getService<Foo>()), isTrue);
  });

  test('fixed: InjectorToken subclass works in Provider but not in getService/Dependency', () async {
    final token = MyToken();
    final injector = Injector([Provider.value(token, 'v')]);
    expect(await injector.getService<String>(token).timeout(_t), 'v');
  });

  test('fixed: alias cycle overflows the stack instead of an InjectorError', () async {
    final injector = Injector([Provider.existing(CycA, CycB), Provider.existing(CycB, CycA)]);
    await expectLater(injector.getService<CycA>().timeout(_t), throwsA(isA<InjectorError>()));
  });

  test('fixed: Injector is seeded as a dependency but cannot be resolved', () async {
    final injector = Injector([]);
    expect(await injector.getService<Injector>().timeout(_t), same(injector));
  });
}
