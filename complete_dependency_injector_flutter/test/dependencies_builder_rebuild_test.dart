import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';

/// A ViewModel that observes an arbitrary stream supplied by the test, so the
/// tests can use streams that don't replay their latest value.
class StreamViewModel extends DependencyBuilderViewModelBase {
  final Stream<int> source;
  String? value;
  int? count;

  StreamViewModel(this.source) : super(dependencyDataList: DependencyDataBuilder.list([String]));

  @override
  void setPropertiesOnDependencyResolution(Dependencies dependencies) {
    value = dependencies<String>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [source];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    count = snapshots[0] as int;
  }
}

Widget _view(StreamViewModel vm) => DependenciesBuilder<StreamViewModel>(
      cleanViewModelInstance: vm,
      builder: (context, vm) {
        if (vm.error) return const Text('error', textDirection: TextDirection.ltr);
        if (vm.loading) return const Text('loading', textDirection: TextDirection.ltr);
        return Text('${vm.value}:${vm.count}', textDirection: TextDirection.ltr);
      },
    );

/// Stream events reach a StreamBuilder a frame after they are added.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('stays ready when a parent rebuilds and the stream does not replay', (tester) async {
    final controller = StreamController<int>.broadcast();
    final vm = StreamViewModel(controller.stream);
    late StateSetter rebuildParent;

    await tester.pumpWidget(InjectorRootWidget(
      injector: Injector([Provider.value(String, 'v')]),
      child: StatefulBuilder(builder: (context, setState) {
        rebuildParent = setState;
        return _view(vm);
      }),
    ));
    await tester.pump();
    await tester.pump();
    controller.add(1);
    await _settle(tester);
    expect(find.text('v:1'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();
    await tester.pump();

    expect(find.text('v:1'), findsOneWidget, reason: 'a parent rebuild must not drop the ViewModel back to loading');
    await controller.close();
  });

  testWidgets('a parent rebuild does not re-listen to a single-subscription stream', (tester) async {
    final controller = StreamController<int>();
    final vm = StreamViewModel(controller.stream);
    late StateSetter rebuildParent;

    await tester.pumpWidget(InjectorRootWidget(
      injector: Injector([Provider.value(String, 'v')]),
      child: StatefulBuilder(builder: (context, setState) {
        rebuildParent = setState;
        return _view(vm);
      }),
    ));
    await tester.pump();
    await tester.pump();
    controller.add(1);
    await _settle(tester);
    expect(find.text('v:1'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();

    expect(tester.takeException(), isNull);
    controller.add(2);
    await _settle(tester);
    expect(find.text('v:2'), findsOneWidget);
    await controller.close();
  });

  testWidgets('a ViewModel created inside build (the README pattern) keeps its state across parent rebuilds', (tester) async {
    final controller = StreamController<int>.broadcast();
    var created = 0;
    late StateSetter rebuildParent;

    await tester.pumpWidget(InjectorRootWidget(
      injector: Injector([Provider.value(String, 'v')]),
      child: StatefulBuilder(builder: (context, setState) {
        rebuildParent = setState;
        created++;
        return _view(StreamViewModel(controller.stream));
      }),
    ));
    await tester.pump();
    await tester.pump();
    controller.add(1);
    await _settle(tester);
    expect(find.text('v:1'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();
    await tester.pump();

    expect(created, 2);
    expect(find.text('v:1'), findsOneWidget);
    await controller.close();
  });

  testWidgets('error clears once the stream recovers', (tester) async {
    final controller = StreamController<int>.broadcast();
    final vm = StreamViewModel(controller.stream);

    await tester.pumpWidget(InjectorRootWidget(
      injector: Injector([Provider.value(String, 'v')]),
      child: _view(vm),
    ));
    await tester.pump();
    await tester.pump();
    controller.add(1);
    await _settle(tester);
    controller.addError(StateError('boom'));
    await _settle(tester);
    expect(find.text('error'), findsOneWidget);

    controller.add(2);
    await _settle(tester);
    expect(vm.error, isFalse);
    expect(find.text('v:2'), findsOneWidget);
    await controller.close();
  });

  testWidgets('two scopes sharing one DependencyData each get their own instances', (tester) async {
    // A ViewModel whose DependencyData is a static field, shared by every instance.
    final shared = DependencyDataBuilder.list([String]);
    Widget scoped(String value) => InjectorScopeWidget(
          providers: [Provider.value(String, value)],
          child: DependenciesBuilder<SharedDataViewModel>(
            cleanViewModelInstance: SharedDataViewModel(shared),
            builder: (context, vm) => Text(vm.loading ? 'loading' : vm.value!, textDirection: TextDirection.ltr),
          ),
        );

    await tester.pumpWidget(InjectorRootWidget(
      injector: Injector([]),
      child: Column(children: [scoped('a'), scoped('b')]),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });
}

class SharedDataViewModel extends DependencyBuilderViewModelBase {
  String? value;
  SharedDataViewModel(DependencyData data) : super(dependencyDataList: data);

  @override
  void setPropertiesOnDependencyResolution(Dependencies dependencies) => value = dependencies<String>();

  @override
  Iterable<Stream> getListOfStreamsToObserve() => const [];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {}
}
