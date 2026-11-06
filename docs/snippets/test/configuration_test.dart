import 'package:complete_dependency_injector_docs_snippets/configuration.dart';
import 'package:test/test.dart';

void main() {
  test('each environment supplies its own values', () async {
    final result = await runConfiguration();
    expect(result['development'], {
      'baseUrl': 'http://localhost:8080',
      'timeout': const Duration(seconds: 30),
      'sentry': null,
      'newCheckout': true,
    });
    expect(result['production'], {
      'baseUrl': 'https://api.example.com',
      'timeout': const Duration(seconds: 5),
      'sentry': 'https://key@sentry.example.com/1',
      'newCheckout': false,
    });
  });
}
