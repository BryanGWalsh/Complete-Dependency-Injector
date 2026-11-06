import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class Greeter {
  Greeter(this.name);
  final String name;
}

class Endpoint {
  Endpoint({required this.host, required this.port});
  final String host;
  final int port;
}

void main() {
  setUpAll(() {
    Injector([]).registerFactories([
      InjectableFactory.withDependencies<Greeter>(
        DependencyDataBuilder.list([String]),
        (deps) => Greeter(deps.get<String>()),
      ),
      InjectableFactory.withDependencies<Endpoint>(
        DependencyDataBuilder.namedRequired({'host': String, 'port': int}).done(),
        (deps) => deps.invokeApply(Endpoint.new),
      ),
    ]);
  });

  group('one DependencyData resolved in several injectors at once', () {
    test('a factory provided in two scopes builds each with its own scope\'s dependencies', () async {
      final root = Injector([]);
      final a = Injector([Provider.value(String, 'a'), Provider(Greeter)], parent: root);
      final b = Injector([Provider.value(String, 'b'), Provider(Greeter)], parent: root);

      final greeters = await Future.wait([a.getService<Greeter>(), b.getService<Greeter>()]);

      expect(greeters.map((g) => g.name), ['a', 'b']);
    });

    test('invokeApply passes each scope its own named dependencies', () async {
      final a = Injector([Provider.value(String, 'a.example'), Provider.value(int, 1), Provider(Endpoint)]);
      final b = Injector([Provider.value(String, 'b.example'), Provider.value(int, 2), Provider(Endpoint)]);

      final endpoints = await Future.wait([a.getService<Endpoint>(), b.getService<Endpoint>()]);

      expect(endpoints.map((e) => '${e.host}:${e.port}'), ['a.example:1', 'b.example:2']);
    });

    test('a Dependencies result is not changed by a later resolution of the same data', () async {
      final data = DependencyDataBuilder.list([String]);
      final first = await Injector([Provider.value(String, 'first')]).resolveDependencies(data);
      await Injector([Provider.value(String, 'second')]).resolveDependencies(data);

      expect(first.get<String>(), 'first');
    });
  });

  group('DependencyDataBuilder', () {
    test('named() accepts only required dependencies', () {
      final data = DependencyDataBuilder().named(required: {'host': String}).done();
      expect(data.named.length, 1);
    });

    test('named() accepts only optional dependencies', () {
      final data = DependencyDataBuilder().named(optional: {'host': String}).done();
      expect(data.named.values.single.optional, isTrue);
    });

    test('namedRequired factory honours safety: false', () {
      final builder = DependencyDataBuilder.namedRequired({'host': String}, safety: false);
      expect(() => builder.namedRequired({'port': int}), returnsNormally);
    });

    test('namedOptional factory honours safety: false', () {
      final builder = DependencyDataBuilder.namedOptional({'host': String}, safety: false);
      expect(() => builder.namedOptional({'port': int}), returnsNormally);
    });
  });
}
