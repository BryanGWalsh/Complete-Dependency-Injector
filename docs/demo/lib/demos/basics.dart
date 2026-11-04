// The basics: a root-scoped service, a ViewModel and DependenciesBuilder.
// Shown on docs/demos/index.md and docs/use-cases pages.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

// #region service
/// App-wide counter. Provided at the root, so every screen shares one.
class CounterService implements InjectableWithDisposeInterface {
  static final Factory = InjectableFactory.withoutDependencies<CounterService>(
    () => CounterService(),
  );
  static final DefaultProvider = Provider(CounterService);

  // State lives in a stream, not in plain fields.
  final _count = BehaviorSubject<int>.seeded(0);
  Stream<int> get count => _count.stream;

  void increment() => _count.add(_count.value + 1);

  @override
  Future<void> dispose() => _count.close();
}
// #endregion service

// #region view-model
class CounterViewModel extends DependencyBuilderViewModelBase {
  CounterViewModel()
      : super(dependencyDataList: DependencyDataBuilder.list([CounterService]));

  late CounterService _counter;
  int count = 0;

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    _counter = deps<CounterService>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [_counter.count];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    count = snapshots[0] as int;
  }

  void increment() => _counter.increment();
}
// #endregion view-model

// #region widget
class BasicsDemo extends StatelessWidget {
  const BasicsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DependenciesBuilder<CounterViewModel>(
      cleanViewModelInstance: CounterViewModel(),
      builder: (context, vm) => dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
        context: context,
        viewModel: vm,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        build: (context, vm) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${vm.count}', key: const Key('count'), style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: vm.increment,
                icon: const Icon(Icons.add),
                label: const Text('Increment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// #endregion widget
