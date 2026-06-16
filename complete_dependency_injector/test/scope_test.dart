import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

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
}
