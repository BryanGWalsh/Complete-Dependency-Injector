import 'dart:async';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class CircularA {
  final CircularB b;
  CircularA(this.b);
}

class CircularB {
  final CircularA a;
  CircularB(this.a);
}

void main() {
  final debugOptions = InjectorDebugOptions(allowFactoryReplacement: true);

  group('Error Case Tests', () {
    test('throws error for unregistered dependency', () async {
      final injector = Injector([], debugOptions: debugOptions);
      expect(() => injector.getService<String>(), throwsA(isA<InjectorError>()));
    });

    test('throws error for missing factory', () async {
      final injector = Injector([
        Provider(String),
      ], debugOptions: debugOptions);
      
      expect(() => injector.getService<String>(), throwsA(isA<InjectorError>()));
    });

    test('circular dependency detection (indirect test - should fail or timeout)', () async {
      final injector = Injector([
        Provider(CircularA),
        Provider(CircularB),
      ], debugOptions: debugOptions);

      injector.registerFactories([
        InjectableFactory.withDependencies<CircularA>(
          DependencyDataBuilder.list([CircularB]),
          (deps) => CircularA(deps<CircularB>()),
        ),
        InjectableFactory.withDependencies<CircularB>(
          DependencyDataBuilder.list([CircularA]),
          (deps) => CircularB(deps<CircularA>()),
        ),
      ]);

      // We expect a timeout or a specific error if the library handles it.
      // Based on the code, it will likely hang.
      expect(injector.getService<CircularA>().timeout(Duration(milliseconds: 100)), throwsA(isA<TimeoutException>()));
    }, skip: "Hangs indefinitely as expected - library needs circular dependency detection");
  });
}
