// Samples for docs/use-cases/configuration.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

// #region tokens
// Plain values like a String or Duration have no class of their own to use
// as a token, so give each one a name.
final apiBaseUrl = InjectorToken.fromString('apiBaseUrl');
final requestTimeout = InjectorToken.fromString('requestTimeout');
final sentryDsn = InjectorToken.fromString('sentryDsn');
// #endregion tokens

// #region typed
/// Settings that travel together can be one class, used as its own token.
class FeatureFlags {
  const FeatureFlags({this.newCheckout = false});
  final bool newCheckout;
}
// #endregion typed

// #region consumer
class ApiClient {
  ApiClient({required this.baseUrl, required this.timeout, this.sentry, required this.flags});

  static final Factory = InjectableFactory.withDependencies<ApiClient>(
    DependencyDataBuilder.list([apiBaseUrl, requestTimeout, sentryDsn, FeatureFlags]),
    (deps) => ApiClient(
      baseUrl: deps.get<String>(apiBaseUrl),
      timeout: deps.get<Duration>(requestTimeout),
      // Not every environment sets this one, so read it as optional.
      sentry: deps.getOptional<String>(sentryDsn),
      flags: deps.get<FeatureFlags>(),
    ),
  );
  static final DefaultProvider = Provider(ApiClient);

  final String baseUrl;
  final Duration timeout;
  final String? sentry;
  final FeatureFlags flags;
}
// #endregion consumer

// #region environments
enum AppEnvironment { development, production }

/// Every setting for one environment, as a list of providers.
List<Provider> configFor(AppEnvironment env) => switch (env) {
      AppEnvironment.development => [
          Provider.value(apiBaseUrl, 'http://localhost:8080'),
          Provider.value(requestTimeout, const Duration(seconds: 30)),
          Provider.value(FeatureFlags, const FeatureFlags(newCheckout: true)),
        ],
      AppEnvironment.production => [
          Provider.value(apiBaseUrl, 'https://api.example.com'),
          Provider.value(requestTimeout, const Duration(seconds: 5)),
          Provider.value(sentryDsn, 'https://key@sentry.example.com/1'),
          Provider.value(FeatureFlags, const FeatureFlags()),
        ],
    };
// #endregion environments

Future<Map<String, Object?>> describeClient(AppEnvironment env) async {
  // #region root
  final root = Injector([
    ...configFor(env),
    ApiClient.DefaultProvider,
  ]);
  // #endregion root

  final client = await root.getService<ApiClient>();
  final result = {
    'baseUrl': client.baseUrl,
    'timeout': client.timeout,
    'sentry': client.sentry,
    'newCheckout': client.flags.newCheckout,
  };
  await root.dispose();
  return result;
}

Future<Map<String, Object?>> runConfiguration() async {
  // #region register
  // Factories are global: register them once, before building any injector.
  Injector([]).registerFactories([ApiClient.Factory]);
  // #endregion register

  return {
    'development': await describeClient(AppEnvironment.development),
    'production': await describeClient(AppEnvironment.production),
  };
}
