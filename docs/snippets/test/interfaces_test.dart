import 'package:complete_dependency_injector_docs_snippets/interfaces.dart';
import 'package:test/test.dart';

void main() {
  test('an interface resolves to its derived implementation', () async {
    final result = await runInterfaces();
    expect(result['isConsole'], isTrue);
    expect(result['sameInstance'], isTrue);
    expect(result['sent'], ['order_placed']);
    expect(result['aliasesShareInstance'], isTrue);
    expect(result['theme'], 'dark');
  });
}
