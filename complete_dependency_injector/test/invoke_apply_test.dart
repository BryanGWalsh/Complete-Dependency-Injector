import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

class TestService {
  final String name;
  final int value;
  
  TestService(this.name, {required this.value});
}

void main() {
  test('Dependencies.invokeApply works correctly', () async {
    final injector = Injector([
      Provider.value(String, "TestName"),
      Provider.value(int, 42),
    ]);

    final data = DependencyDataBuilder()
      .positional([String])
      .namedRequired({'value': int})
      .done();

    final dependencies = await injector.resolveDependencies(data);
    
    // Testing invokeApply with a constructor
    final service = dependencies.invokeApply<TestService>(TestService.new);
    
    expect(service.name, "TestName");
    expect(service.value, 42);
  });
}
