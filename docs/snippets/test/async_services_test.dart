import 'package:complete_dependency_injector_docs_snippets/async_services.dart';
import 'package:test/test.dart';

void main() {
  test('dependents wait for a ready service', () async {
    final result = await runAsyncServices();
    expect(result['dbWasOpen'], isTrue);
    expect(result['users'], ['Ada', 'Grace']);
  });
}
