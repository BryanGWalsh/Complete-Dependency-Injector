import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyDataBuilder Unit Tests', () {
    test('builds positional dependencies from a list', () {
      final data = DependencyDataBuilder.list([String, int, double]);
      
      expect(data.positionalSorted.length, 3);
      expect(data.positionalSorted.elementAt(0).tokenString, contains("type_String"));
      expect(data.positionalSorted.elementAt(1).tokenString, contains("type_int"));
      expect(data.positionalSorted.elementAt(2).tokenString, contains("type_double"));
    });

    test('builds named dependencies', () {
      final stringToken = InjectorToken.fromType(String).tokenRepresentation;
      final intToken = InjectorToken.fromType(int).tokenRepresentation;
      
      final data = DependencyDataBuilder.named(
        required: {'apiKey': String},
        optional: {'timeout': int},
      ).done();
      
      expect(data.named.length, 2);
      expect(data.named[stringToken]!.parameterName, 'apiKey');
      expect(data.named[intToken]!.parameterName, 'timeout');
    });

    test('empty builder produces empty data', () {
      final data = DependencyDataBuilder.empty;
      expect(data.all, isEmpty);
      expect(data.positionalSorted, isEmpty);
    });
  });
}
