import 'dart:async';

import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class CycleA {
  CycleA(this.b);
  final CycleB b;
}

class CycleB {
  CycleB(this.a);
  final CycleA a;
}

class Label {
  Label(this.value);
  final String value;
}

/// Becomes ready a little later, so both scopes below are mid-resolution
/// at the same time.
class Slow with InjectableWithReadyMixin {
  Slow() {
    Future.delayed(const Duration(milliseconds: 10), () => setInjectableReadyResult(true));
  }
}

class LabelConsumer {
  LabelConsumer(this.label);
  final Label label;
}

class NeedsInjector {
  NeedsInjector(this.injector);
  final Injector injector;
}

class NamedToken extends InjectorToken {
  NamedToken(super.identifier) : super.fromString();
}

final aliasA = InjectorToken.fromString('aliasCycleA');
final aliasB = InjectorToken.fromString('aliasCycleB');
final dangling = InjectorToken.fromString('danglingAlias');

void main() {
  setUpAll(() {
    Injector([]).registerFactories([
      InjectableFactory.withDependencies<CycleA>(
        DependencyDataBuilder.positional([CycleB]).done(),
        (deps) => CycleA(deps()),
      ),
      InjectableFactory.withDependencies<CycleB>(
        DependencyDataBuilder.positional([CycleA]).done(),
        (deps) => CycleB(deps()),
      ),
      InjectableFactory.withoutDependencies<Slow>(() => Slow()),
      InjectableFactory.withDependencies<LabelConsumer>(
        DependencyDataBuilder.positional([Label, Slow]).done(),
        (deps) => LabelConsumer(deps()),
      ),
      InjectableFactory.withDependencies<NeedsInjector>(
        DependencyDataBuilder.positional([Injector]).done(),
        (deps) => NeedsInjector(deps()),
      ),
    ]);
  });

  group('cycles', () {
    test('a factory cycle fails with an InjectorError naming the cycle', () async {
      final injector = Injector([Provider(CycleA), Provider(CycleB)]);
      await expectLater(
        injector.getService<CycleA>().timeout(const Duration(seconds: 2)),
        throwsA(isA<InjectorError>().having((e) => e.message, 'message', contains('Circular'))),
      );
    });

    test('an alias cycle fails with an InjectorError', () async {
      final injector = Injector([Provider.existing(aliasA, aliasB), Provider.existing(aliasB, aliasA)]);
      await expectLater(
        injector.getService<Object>(aliasA),
        throwsA(isA<InjectorError>().having((e) => e.message, 'message', contains('Circular'))),
      );
    });
  });

  group('scopes resolving the same factory at the same time', () {
    test('each scope gets its own dependencies', () async {
      final root = Injector([Provider(Slow)]);
      final a = Injector([Provider.value(Label, Label('a')), Provider(LabelConsumer)], parent: root);
      final b = Injector([Provider.value(Label, Label('b')), Provider(LabelConsumer)], parent: root);

      final results = await Future.wait([a.getService<LabelConsumer>(), b.getService<LabelConsumer>()]);

      expect(results[0].label.value, 'a');
      expect(results[1].label.value, 'b');
    });

    test('resolveDependencies with one DependencyData in two injectors', () async {
      final data = DependencyDataBuilder.positional([Label]).done();
      final a = Injector([Provider.value(Label, Label('a'))]);
      final b = Injector([Provider.value(Label, Label('b'))]);

      final results = await Future.wait([a.resolveDependencies(data), b.resolveDependencies(data)]);

      expect(results[0]<Label>().value, 'a');
      expect(results[1]<Label>().value, 'b');
    });
  });

  group('Injector as a dependency', () {
    test('getService<Injector> returns the injector itself', () async {
      final injector = Injector([]);
      expect(await injector.getService<Injector>(), same(injector));
    });

    test('a child injector returns itself, not its parent', () async {
      final parent = Injector([]);
      final child = Injector([], parent: parent);
      expect(await child.getService<Injector>(), same(child));
    });

    test('a factory can depend on Injector', () async {
      final injector = Injector([Provider(NeedsInjector)]);
      final service = await injector.getService<NeedsInjector>();
      expect(service.injector, same(injector));
    });
  });

  group('tokens', () {
    test('a subclass of InjectorToken works with getService', () async {
      final token = NamedToken('apiUrl');
      final injector = Injector([Provider.value(token, 'https://example.com')]);
      expect(await injector.getService<String>(token), 'https://example.com');
    });
  });

  group('aliases', () {
    test('an optional lookup of a dangling alias does not turn later required lookups into null', () async {
      final injector = Injector([Provider.existing(dangling, Label)]);

      expect(await injector.getServiceOrNull<Label>(dangling), isNull);
      await expectLater(injector.getService<Label>(dangling), throwsA(isA<InjectorError>()));
    });
  });
}
