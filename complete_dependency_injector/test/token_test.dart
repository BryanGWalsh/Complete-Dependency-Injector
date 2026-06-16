import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

void main() {
  group('InjectorToken Unit Tests', () {
    test('fromString creates stable representation', () {
      final token1 = InjectorToken.fromString("auth");
      final token2 = InjectorToken.fromString("auth");
      
      expect(token1.tokenRepresentation, equals(token2.tokenRepresentation));
      expect(token1.tokenRepresentation, contains("string_auth"));
    });

    test('fromType creates stable representation for the same type', () {
      final token1 = InjectorToken.fromType(String);
      final token2 = InjectorToken.fromType(String);
      
      expect(token1.tokenRepresentation, equals(token2.tokenRepresentation));
      expect(token1.tokenRepresentation, contains("type_String"));
    });

    test('fromCounter produces unique tokens', () {
      final token1 = InjectorToken.fromCounter();
      final token2 = InjectorToken.fromCounter();
      
      expect(token1.tokenRepresentation, isNot(equals(token2.tokenRepresentation)));
      expect(token1.tokenRepresentation, contains("counter_"));
    });

    test('fromTokenOrType handles both inputs', () {
      final token = InjectorToken.fromString("custom");
      expect(InjectorToken.fromTokenOrType(token), same(token));
      
      final typeToken = InjectorToken.fromTokenOrType(int);
      expect(typeToken.tokenRepresentation, contains("type_int"));
    });
  });
}
