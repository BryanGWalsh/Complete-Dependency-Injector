// Injector widgets: InjectorRootWidget, InjectorScopeWidget, reading the
// nearest injector, overriding a parent, and scope disposal.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';

// #region greeting
/// A plain value class, provided with Provider.value (no factory needed).
class Greeting {
  const Greeting(this.text);
  final String text;
}
// #endregion greeting

// #region read-injector
/// Reads from the nearest injector above it in the tree.
class GreetingText extends StatelessWidget {
  const GreetingText({super.key});

  @override
  Widget build(BuildContext context) {
    final injector = InjectorContainerWidget.of(context)!.injector;
    return FutureBuilder<Greeting>(
      future: injector.getService<Greeting>(),
      builder: (context, snapshot) => Text(snapshot.data?.text ?? '...'),
    );
  }
}
// #endregion read-injector

// #region lifecycle
/// Provided by the session scope, so the scope owns it and disposes it.
class ScopeSession implements InjectableWithDisposeInterface {
  static final Factory = InjectableFactory.withoutDependencies<ScopeSession>(
    () => ScopeSession(),
  );
  static final DefaultProvider = Provider(ScopeSession);

  static final disposedCount = ValueNotifier<int>(0);

  @override
  Future<void> dispose() async => disposedCount.value++;
}
// #endregion lifecycle

class InjectorWidgetsDemo extends StatelessWidget {
  const InjectorWidgetsDemo({super.key});

  static final _showSessionScope = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // #region nested
        InjectorScopeWidget(
          providers: [Provider.value(Greeting, const Greeting('Hello from the outer scope'))],
          child: _Box(
            label: 'Outer InjectorScopeWidget',
            children: [
              const GreetingText(),
              // A nested scope can override what its parent provides.
              InjectorScopeWidget(
                providers: [Provider.value(Greeting, const Greeting('Hello from the inner scope'))],
                child: const _Box(label: 'Inner InjectorScopeWidget', children: [GreetingText()]),
              ),
            ],
          ),
        ),
        // #endregion nested
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: _showSessionScope,
          builder: (context, show, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: const Text('Show session scope'),
                value: show,
                onChanged: (value) => _showSessionScope.value = value,
              ),
              // #region dispose
              if (show)
                InjectorScopeWidget(
                  providers: [ScopeSession.DefaultProvider],
                  child: Builder(
                    builder: (context) => FutureBuilder(
                      // Creates this scope's ScopeSession.
                      future: InjectorContainerWidget.of(context)!.injector.getService<ScopeSession>(),
                      builder: (context, snapshot) => _Box(
                        label: 'Session scope',
                        children: [Text(snapshot.hasData ? 'ScopeSession is alive' : '...')],
                      ),
                    ),
                  ),
                ),
              // #endregion dispose
            ],
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: ScopeSession.disposedCount,
          builder: (context, count, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Sessions disposed: $count', key: const Key('disposed-count')),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          ...children,
        ],
      ),
    );
  }
}
