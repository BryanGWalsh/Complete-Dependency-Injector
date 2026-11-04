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

  static final Factory = InjectableFactory.withoutDependencies<SlowDatabase>(
    () => SlowDatabase(),
  );
  static final DefaultProvider = Provider(SlowDatabase);

  static Duration openDelay = const Duration(seconds: 2);

  // null while (re)loading, so the UI can show progress after the first load.
  final _users = BehaviorSubject<List<String>?>();
  Stream<List<String>?> get users => _users.stream;

  Future<void> _open() async {
    await _load(); // pretend to connect and query
    setInjectableReadyResult(true); // now the injector hands it out
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    _users.add(null);
    await Future<void>.delayed(openDelay);
    _users.add(['Ada Lovelace', 'Grace Hopper', 'Margaret Hamilton']);
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
  List<String>? users;

  bool get reloading => users == null;

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    _db = deps<SlowDatabase>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [_db.users];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    users = snapshots[0] as List<String>?;
  }

  void reload() => _db.reload();
}
// #endregion view-model

// #region widget
const _opening = Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Opening database...')],
  ),
);

/// No StatefulWidget needed: the loading and reload state live in the
/// service's stream, and DependenciesBuilder rebuilds when it changes.
class AsyncLoadingDemo extends StatelessWidget {
  const AsyncLoadingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return InjectorScopeWidget(
      providers: [SlowDatabase.DefaultProvider],
      child: DependenciesBuilder<UsersViewModel>(
        cleanViewModelInstance: UsersViewModel(),
        builder: (context, vm) => dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
          context: context,
          viewModel: vm,
          // Shown until SlowDatabase is ready.
          loadingWidget: _opening,
          build: (context, vm) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: vm.reloading ? null : vm.reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ),
              Expanded(
                child: vm.reloading
                    ? _opening
                    : ListView(
                        children: [
                          for (final name in vm.users!) ListTile(leading: const Icon(Icons.person), title: Text(name)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// #endregion widget
