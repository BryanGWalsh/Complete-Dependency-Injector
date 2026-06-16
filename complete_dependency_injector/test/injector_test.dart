import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:test/test.dart';

abstract class AuthService {
  String login();
}

class AuthServiceImpl implements AuthService {
  @override
  String login() => "Logged in";
}

class ApiService {
  final AuthService auth;
  ApiService(this.auth);
  String fetchData() => "Data with ${auth.login()}";
}

void main() {
  group('Injector Basic Resolution', () {
    test('resolves a simple value provider', () async {
      final injector = Injector([
        Provider.value(String, "TestValue"),
      ]);

      final value = await injector.getService<String>();
      expect(value, "TestValue");
    });

    test('resolves a factory with dependencies', () async {
      final injector = Injector([
        Provider(AuthService, fromDerived: AuthServiceImpl),
        Provider(ApiService),
      ]);

      injector.registerFactories([
        InjectableFactory.withoutDependencies<AuthServiceImpl>(() => AuthServiceImpl()),
        InjectableFactory.withDependencies<ApiService>(
          DependencyDataBuilder.list([AuthService]),
          (deps) => ApiService(deps<AuthService>()),
        ),
      ]);

      final api = await injector.getService<ApiService>();
      expect(api.fetchData(), "Data with Logged in");
    });
  });

  group('Injector Error Handling', () {
    test('throws when dependency is missing', () async {
      final injector = Injector([]);
      expect(() => injector.getService<String>(), throwsA(isA<InjectorError>()));
    });
  });
}
