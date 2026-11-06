// Samples for docs/use-cases/interfaces.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

// #region interface
/// What the rest of the app depends on.
abstract class Analytics {
  // Ask for Analytics, get a ConsoleAnalytics.
  static final DefaultProvider = Provider.factory(Analytics, fromDerived: ConsoleAnalytics);

  void track(String event);
}
// #endregion interface

// #region implementation
/// One concrete implementation. Only this class has a factory.
class ConsoleAnalytics implements Analytics {
  static final Factory = InjectableFactory.withoutDependencies<ConsoleAnalytics>(
    () => ConsoleAnalytics(),
  );

  final List<String> sent = [];

  @override
  void track(String event) {
    sent.add(event);
    print('analytics: $event');
  }
}
// #endregion implementation

// #region consumer
/// Depends on the interface, never on ConsoleAnalytics.
class CheckoutService {
  CheckoutService(this._analytics);

  static final Factory = InjectableFactory.withDependencies<CheckoutService>(
    DependencyDataBuilder.list([Analytics]),
    (deps) => CheckoutService(deps.get<Analytics>()),
  );
  static final DefaultProvider = Provider(CheckoutService);

  final Analytics _analytics;

  void placeOrder() => _analytics.track('order_placed');
}
// #endregion consumer

// #region multi
/// One class that fills two roles.
abstract class SettingsReader {
  String? read(String key);
}

abstract class SettingsWriter {
  void write(String key, String value);
}

class MemorySettings implements SettingsReader, SettingsWriter {
  static final Factory = InjectableFactory.withoutDependencies<MemorySettings>(
    () => MemorySettings(),
  );
  // One instance, reachable by three tokens.
  static final DefaultProvider = Provider.factory(
    MemorySettings,
    aliasTokens: [SettingsReader, SettingsWriter],
  );

  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;
}
// #endregion multi

Future<Map<String, Object?>> runInterfaces() async {
  // #region use
  final root = Injector([
    Analytics.DefaultProvider,
    CheckoutService.DefaultProvider,
    MemorySettings.DefaultProvider,
  ]);
  root.registerFactories([
    ConsoleAnalytics.Factory,
    CheckoutService.Factory,
    MemorySettings.Factory,
  ]);

  final checkout = await root.getService<CheckoutService>();
  checkout.placeOrder(); // analytics: order_placed

  // Asking for the interface or the implementation gives the same instance.
  final analytics = await root.getService<Analytics>();
  final console = await root.getService<ConsoleAnalytics>();
  print(identical(analytics, console)); // true

  // Aliases: write through one role, read through the other.
  final writer = await root.getService<SettingsWriter>();
  final reader = await root.getService<SettingsReader>();
  writer.write('theme', 'dark');
  print(reader.read('theme')); // dark
  // #endregion use

  final result = {
    'isConsole': analytics is ConsoleAnalytics,
    'sameInstance': identical(analytics, console),
    'sent': List<String>.of(console.sent),
    'aliasesShareInstance': identical(writer, reader),
    'theme': reader.read('theme'),
  };
  await root.dispose();
  return result;
}
