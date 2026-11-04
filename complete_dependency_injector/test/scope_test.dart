import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class Shared {}

class PerScope implements InjectableWithDisposeInterface {
  bool disposed = false;
  @override
  Future<void> dispose() async => disposed = true;
}


void main() {
  group('Hierarchical Scopes', () {
    test('child injector inherits from parent', () async {
      final parent = Injector([
        Provider.value(String, "ParentValue"),
      ]);

      final child = Injector([], parent: parent);

      final value = await child.getService<String>();
      expect(value, "ParentValue");
    });

    test('child injector overrides parent', () async {
      final parent = Injector([
        Provider.value(String, "ParentValue"),
      ]);

      final child = Injector([
        Provider.value(String, "ChildValue"),
      ], parent: parent);

      final value = await child.getService<String>();
      expect(value, "ChildValue");
      
      final parentValue = await parent.getService<String>();
      expect(parentValue, "ParentValue");
    });
  
  });

  group('Provider location decides where instances live', () {
    final debugOptions = InjectorDebugOptions(allowFactoryReplacement: true);

    test('provided at the root: one instance shared by all children', () async {
      final root = Injector([Provider(Shared)], debugOptions: debugOptions);
      root.registerFactory(InjectableFactory.withoutDependencies<Shared>(() => Shared()));
      final a = Injector([], parent: root);
      final b = Injector([], parent: root);

      final fromA = await a.getService<Shared>();
      expect(identical(fromA, await b.getService<Shared>()), isTrue);
      expect(identical(fromA, await root.getService<Shared>()), isTrue);
    });

    test('provided in a child: one instance per child, cached across requests', () async {
      final root = Injector([], debugOptions: debugOptions);
      root.registerFactory(InjectableFactory.withoutDependencies<PerScope>(() => PerScope()));
      final a = Injector([Provider(PerScope)], parent: root);
      final b = Injector([Provider(PerScope)], parent: root);

      final a1 = await a.getService<PerScope>();
      final a2 = await a.getService<PerScope>();
      final b1 = await b.getService<PerScope>();
      expect(identical(a1, a2), isTrue);
      expect(identical(a1, b1), isFalse);
    });

    test('a child can override a root-provided service with its own instance', () async {
      final root = Injector([Provider(Shared)], debugOptions: debugOptions);
      root.registerFactory(InjectableFactory.withoutDependencies<Shared>(() => Shared()));
      final child = Injector([Provider(Shared)], parent: root);

      final fromRoot = await root.getService<Shared>();
      final fromChild = await child.getService<Shared>();
      expect(identical(fromRoot, fromChild), isFalse);
      expect(identical(fromChild, await child.getService<Shared>()), isTrue);
    });

    test('disposing a child disposes the instances it owns', () async {
      final root = Injector([], debugOptions: debugOptions);
      root.registerFactory(InjectableFactory.withoutDependencies<PerScope>(() => PerScope()));
      final child = Injector([Provider(PerScope)], parent: root);

      final service = await child.getService<PerScope>();
      await child.dispose();
      expect(service.disposed, isTrue);
    });
  });
}
