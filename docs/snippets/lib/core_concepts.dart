// Samples for docs/guide/core-concepts.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

// #region convention
class ApiClient {
  static final Factory = InjectableFactory.withoutDependencies<ApiClient>(
    () => ApiClient(),
  );
  static final DefaultProvider = Provider(ApiClient);
}
// #endregion convention

// #region per-child
/// Provided by each child injector, so each child gets its own.
class SessionState {
  static final Factory = InjectableFactory.withoutDependencies<SessionState>(
    () => SessionState(),
  );
  static final DefaultProvider = Provider(SessionState);
}
// #endregion per-child

// #region interface
abstract class Clock {
  // Ask for a Clock, get a SystemClock.
  static final DefaultProvider = Provider.factory(Clock, fromDerived: SystemClock);

  DateTime now();
}

class SystemClock implements Clock {
  static final Factory = InjectableFactory.withoutDependencies<SystemClock>(
    () => SystemClock(),
  );

  @override
  DateTime now() => DateTime.now();
}
// #endregion interface

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
    ApiClient.DefaultProvider,
    // An interface backed by an implementation.
    Clock.DefaultProvider,
    // A ready-made value. No factory needed.
    Provider.value(ApiConfig, ApiConfig('https://api.example.com')),
    // A value under a string token, for non-class settings.
    Provider.value(apiBaseUrl, 'https://api.example.com'),
  ]);
  // #endregion providers

  // #region factories
  root.registerFactories([
    ApiClient.Factory,
    SystemClock.Factory,
    SessionState.Factory,
  ]);
  // #endregion factories

  // #region hierarchy
  final screenA = Injector([SessionState.DefaultProvider], parent: root);
  final screenB = Injector([SessionState.DefaultProvider], parent: root);

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
