// Samples for docs/guide/quick-start.md.
// Regions marked with `#region` are pulled into the page.
// #region all
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

// #region services
class Logger {
  // How to build a Logger.
  static final Factory = InjectableFactory.withoutDependencies<Logger>(
    () => Logger(),
  );

  // How to make a Logger available in an injector.
  static final DefaultProvider = Provider(Logger);

  void log(String message) => print('[log] $message');
}

class GreetingService {
  GreetingService(this._logger);

  static final Factory = InjectableFactory.withDependencies<GreetingService>(
    DependencyDataBuilder.list([Logger]),
    (deps) => GreetingService(deps.get<Logger>()),
  );

  static final DefaultProvider = Provider(GreetingService);

  final Logger _logger;

  String greet(String name) {
    _logger.log('greeting $name');
    return 'Hello, $name!';
  }
}
// #endregion services

Future<String> runQuickStart() async {
  // #region injector
  // 1. Say which services this injector makes available.
  final injector = Injector([
    Logger.DefaultProvider,
    GreetingService.DefaultProvider,
  ]);

  // 2. Register how to build each one.
  injector.registerFactories([
    Logger.Factory,
    GreetingService.Factory,
  ]);
  // #endregion injector

  // #region use
  // 3. Ask for a service. Its dependencies are built first.
  final greeter = await injector.getService<GreetingService>();
  final message = greeter.greet('Dart');
  print(message); // Hello, Dart!
  // #endregion use

  await injector.dispose();
  return message;
}

void main() => runQuickStart();
// #endregion all
