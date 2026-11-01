import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';

import 'demos/async_loading.dart';
import 'demos/basics.dart';
import 'demos/scoped_tables.dart';

class Demo {
  const Demo(this.route, this.title, this.description, this.builder);
  final String route;
  final String title;
  final String description;
  final WidgetBuilder builder;
}

final demos = [
  Demo('/basics', 'The basics', 'A shared service and a ViewModel that rebuilds when its stream changes.', (_) => const BasicsDemo()),
  Demo('/async', 'Async services', 'A service that takes two seconds to open, with a loading state.', (_) => const AsyncLoadingDemo()),
  Demo('/tables', 'Scoped services', 'Two tables, each with its own TableManager.', (_) => const ScopedTablesDemo()),
];

// #region root
bool _factoriesRegistered = false;

Injector createRootInjector() {
  final injector = Injector([
    // App-wide services. Scoped services are provided further down the tree.
    CounterService.DefaultProvider,
    ProductRepository.DefaultProvider,
  ]);
  // Factories are global, so register them once per app.
  if (!_factoriesRegistered) {
    injector.registerFactories([
      CounterService.Factory,
      SlowDatabase.Factory,
      ProductRepository.Factory,
      TableManager.Factory,
    ]);
    _factoriesRegistered = true;
  }
  return injector;
}

void main() {
  runApp(InjectorRootWidget(injector: createRootInjector(), child: const DemoApp()));
}
// #endregion root

/// The docs site embeds single screens with `?embed=1`, without the app bar.
final bool embedded = Uri.base.queryParameters['embed'] == '1';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complete Dependency Injector demos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
      routes: {
        '/': (_) => const DemoIndex(),
        for (final d in demos)
          d.route: (context) => Scaffold(
                appBar: embedded ? null : AppBar(title: Text(d.title)),
                body: d.builder(context),
              ),
      },
    );
  }
}

class DemoIndex extends StatelessWidget {
  const DemoIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Dependency Injector demos')),
      body: ListView(
        children: [
          for (final d in demos)
            ListTile(
              title: Text(d.title),
              subtitle: Text(d.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, d.route),
            ),
        ],
      ),
    );
  }
}
