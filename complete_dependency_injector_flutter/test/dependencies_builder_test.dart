import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:rxdart/rxdart.dart';

class MockViewModel extends DependencyBuilderViewModelBase {
  String? value;
  int? count;
  final BehaviorSubject<int> _counter = BehaviorSubject<int>.seeded(0);

  MockViewModel() : super(dependencyDataList: DependencyDataBuilder.list([String]));

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [_counter.stream];

  @override
  void setPropertiesOnDependencyResolution(Dependencies dependenciesContainer) {
    value = dependenciesContainer<String>();
  }

  @override
  void updateViewModelPropertiesOnStreamEmission(List streamSnapshotList) {
    count = streamSnapshotList[0] as int;
  }


  void increment() => _counter.add(_counter.value + 1);

  void dispose() => _counter.close();
}

void main() {
  testWidgets('DependenciesBuilder resolves and builds', (WidgetTester tester) async {
    final injector = Injector([
      Provider.value(String, "TestValue"),
    ]);

    final viewModel = MockViewModel();

    await tester.pumpWidget(
      InjectorRootWidget(
        injector: injector,
        child: MaterialApp(
          home: DependenciesBuilder<MockViewModel>(
            cleanViewModelInstance: viewModel,
            builder: (context, vm) {
              if (vm.loading) return const Text("Loading...");
              return Text("${vm.value}:${vm.count}", textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // Initial pump shows Loading
    expect(find.text("Loading..."), findsOneWidget);

    // Pump again to complete future
    await tester.pump(); // Start future
    await tester.pump(const Duration(milliseconds: 10)); // Complete future

    expect(find.text("TestValue:0"), findsOneWidget);

    // Trigger stream update
    viewModel.increment();
    await tester.pump(Duration.zero); // Process stream emission

    expect(find.text("TestValue:1"), findsOneWidget);

    viewModel.dispose();
    });

    testWidgets('DependenciesBuilder works with simple state handling utility', (WidgetTester tester) async {
    final injector = Injector([
      Provider.value(String, "TestValue"),
    ]);

    final viewModel = MockViewModel();

    await tester.pumpWidget(
      InjectorRootWidget(
        injector: injector,
        child: MaterialApp(
          home: DependenciesBuilder<MockViewModel>(
            cleanViewModelInstance: viewModel,
            builder: (context, vm) {
              return dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
                context: context,
                viewModel: vm,
                build: (context, vm) => Text("Ready: ${vm.value}"),
                loadingWidget: const Text("Still Loading..."),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text("Still Loading..."), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text("Ready: TestValue"), findsOneWidget);
    viewModel.dispose();
    });
    }


