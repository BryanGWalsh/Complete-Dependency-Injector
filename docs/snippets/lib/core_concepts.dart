// Samples for docs/guide/core-concepts.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

class ApiClient {}

class SessionState {}

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

class ApiConfig {
  ApiConfig(this.baseUrl);
  final String baseUrl;
}

// #region tokens
final apiBaseUrl = InjectorToken.fromString('apiBaseUrl');
// #endregion tokens

Future<Map<String, Object>> runCoreConcepts() async {
  // #region providers
  final root = Injector([
    // A type built by its registered factory.
    Provider(ApiClient),
    // A ready-made value. No factory needed.
    Provider.value(ApiConfig, ApiConfig('https://api.example.com')),
    // A value under a string token, for non-class settings.
    Provider.value(apiBaseUrl, 'https://api.example.com'),
    // Ask for Clock, get the SystemClock built by SystemClock's factory.
    Provider.factory(Clock, fromDerived: SystemClock),
  ]);
  // #endregion providers

  // #region factories
  root.registerFactories([
    InjectableFactory.withoutDependencies<ApiClient>(() => ApiClient()),
    InjectableFactory.withoutDependencies<SystemClock>(() => SystemClock()),
    // One SessionState per injector that provides it.
    InjectableFactory.withoutDependencies<SessionState>(
      () => SessionState(),
      scope: InjectableScope.instance,
    ),
  ]);
  // #endregion factories

  // #region hierarchy
  final screenA = Injector([Provider(SessionState)], parent: root);
  final screenB = Injector([Provider(SessionState)], parent: root);

  // Both children share the root's ApiClient...
  final clientA = await screenA.getService<ApiClient>();
  final clientB = await screenB.getService<ApiClient>();
  print(identical(clientA, clientB)); // true

  // ...but each has its own SessionState.
  final sessionA = await screenA.getService<SessionState>();
  final sessionB = await screenB.getService<SessionState>();
  print(identical(sessionA, sessionB)); // false
  // #endregion hierarchy

  final url = await root.getService<String>(apiBaseUrl);
  final clock = await root.getService<Clock>();

  return {
    'sharedClient': identical(clientA, clientB),
    'separateSessions': !identical(sessionA, sessionB),
    'url': url,
    'clockIsSystem': clock is SystemClock,
  };
}
