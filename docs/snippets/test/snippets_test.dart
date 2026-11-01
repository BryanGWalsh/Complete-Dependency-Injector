import 'package:complete_dependency_injector_docs_snippets/core_concepts.dart';
import 'package:complete_dependency_injector_docs_snippets/quick_start.dart';
import 'package:test/test.dart';

void main() {
  test('quick start greets', () async {
    expect(await runQuickStart(), 'Hello, Dart!');
  });

  test('core concepts behave as the page describes', () async {
    final result = await runCoreConcepts();
    expect(result['sharedClient'], isTrue);
    expect(result['separateSessions'], isTrue);
    expect(result['url'], 'https://api.example.com');
    expect(result['clockIsSystem'], isTrue);
  });
}
