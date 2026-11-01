// Async services: a service that needs async setup, and a screen that shows
// a loading state until it's ready.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

// #region service
class SlowDatabase with InjectableWithReadyMixin {
  SlowDatabase() {
    _open();
  }

  // Instance scope: each screen that provides it gets a fresh connection,
  // so reloading the screen opens the database again.
  static final Factory = InjectableFactory.withoutDependencies<SlowDatabase>(
    () => SlowDatabase(),
    scope: InjectableScope.instance,
  );
  static final DefaultProvider = Provider(SlowDatabase);

  static Duration openDelay = const Duration(seconds: 2);

  final _users = BehaviorSubject<List<String>>();
  Stream<List<String>> get users => _users.stream;

  Future<void> _open() async {
    await Future<void>.delayed(openDelay); // pretend to connect
    _users.add(['Ada Lovelace', 'Grace Hopper', 'Margaret Hamilton']);
    setInjectableReadyResult(true); // now the injector hands it out
  }

  @override
  Future<void> dispose() => _users.close();
}
// #endregion service

// #region view-model
class UsersViewModel extends DependencyBuilderViewModelBase {
  UsersViewModel()
      : super(dependencyDataList: DependencyDataBuilder.list([SlowDatabase]));

  late SlowDatabase _db;
  List<String> users = [];

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    _db = deps<SlowDatabase>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [_db.users];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    users = snapshots[0] as List<String>;
  }
}
// #endregion view-model

// #region widget
class AsyncLoadingDemo extends StatefulWidget {
  const AsyncLoadingDemo({super.key});

  @override
  State<AsyncLoadingDemo> createState() => _AsyncLoadingDemoState();
}

class _AsyncLoadingDemoState extends State<AsyncLoadingDemo> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            // A new key builds a new scope, so a new SlowDatabase opens.
            onPressed: () => setState(() => _generation++),
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ),
        Expanded(
          child: InjectorScopeWidget(
            key: ValueKey(_generation),
            providers: [SlowDatabase.DefaultProvider],
            child: DependenciesBuilder<UsersViewModel>(
              cleanViewModelInstance: UsersViewModel(),
              builder: (context, vm) => dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
                context: context,
                viewModel: vm,
                loadingWidget: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Opening database...'),
                    ],
                  ),
                ),
                build: (context, vm) => ListView(
                  children: [for (final name in vm.users) ListTile(leading: const Icon(Icons.person), title: Text(name))],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion widget
