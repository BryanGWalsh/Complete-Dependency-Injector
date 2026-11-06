import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:rxdart/rxdart.dart';

// ---------- helpers ----------

int counterServiceCreated = 0;
int counterServiceDisposed = 0;

class CounterService with InjectableWithDisposeInterface {
  int count = 0;
  CounterService() {
    counterServiceCreated++;
  }
  @override
  Future<void> dispose() async => counterServiceDisposed++;
}

/// Captures the nearest injector on every build.
class InjectorProbe extends StatelessWidget {
  final void Function(Injector) onBuild;
  const InjectorProbe({super.key, required this.onBuild});
  @override
  Widget build(BuildContext context) {
    onBuild(InjectorContainerWidget.of(context)!.injector);
    return const SizedBox();
  }
}

/// Parent whose setState rebuilds [builder].
class Rebuilder extends StatefulWidget {
  final Widget Function(BuildContext, int generation) builder;
  const Rebuilder({super.key, required this.builder});
  @override
  State<Rebuilder> createState() => RebuilderState();
}

class RebuilderState extends State<Rebuilder> {
  int generation = 0;
  void rebuild() => setState(() => generation++);
  @override
  Widget build(BuildContext context) => widget.builder(context, generation);
}

Future<T> resolve<T>(WidgetTester tester, Injector injector) async {
  late T value;
  Object? error;
  injector.getService<T>().then((v) => value = v, onError: (e) => error = e);
  await tester.pump();
  if (error != null) throw error!;
  return value;
}

class StreamVm extends DependencyBuilderViewModelBase {
  final Stream<int> stream;
  String? value;
  int? latest;
  StreamVm(this.stream) : super(dependencyDataList: DependencyDataBuilder.list([String]));
  @override
  Iterable<Stream> getListOfStreamsToObserve() => [stream];
  @override
  void setPropertiesOnDependencyResolution(Dependencies d) => value = d<String>();
  @override
  void updateViewModelPropertiesOnStreamEmission(List l) => latest = l[0] as int;
}

class NoStreamVm extends DependencyBuilderViewModelBase {
  String? value;
  NoStreamVm() : super(dependencyDataList: DependencyDataBuilder.list([String]));
  @override
  Iterable<Stream> getListOfStreamsToObserve() => const [];
  @override
  void setPropertiesOnDependencyResolution(Dependencies d) => value = d<String>();
  @override
  void updateViewModelPropertiesOnStreamEmission(List l) {}
}

class MissingDepVm extends NoStreamVm {
  @override
  DependencyData get dependencyDataList => DependencyDataBuilder.list([double]);
}

Widget stateText(BuildContext context, DependencyBuilderViewModelBase vm) =>
    dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
      context: context,
      viewModel: vm,
      build: (c, vm) => Text('ready ${vm is StreamVm ? '${vm.value}:${vm.latest}' : (vm as NoStreamVm).value}'),
      loadingWidget: const Text('loading'),
      errorWidget: const Text('error'),
    );

Widget app(Injector root, Widget child) =>
    InjectorRootWidget(injector: root, child: Directionality(textDirection: TextDirection.ltr, child: child));

void main() {
  Injector([]).registerFactory(InjectableFactory.withoutDependencies<CounterService>(() => CounterService()));

  // ---------- InjectorScopeWidget ----------

  testWidgets('fixed: scope keeps one injector + service state across parent rebuilds', (tester) async {
    counterServiceCreated = 0;
    final seen = <Injector>{};
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([]),
      Rebuilder(
        key: key,
        builder: (_, _) => InjectorScopeWidget(
          providers: [Provider.factory(CounterService)],
          child: InjectorProbe(onBuild: seen.add),
        ),
      ),
    ));
    final svc = await resolve<CounterService>(tester, seen.single);
    svc.count = 5;
    for (var i = 0; i < 3; i++) {
      key.currentState!.rebuild();
      await tester.pump();
    }
    expect(seen.length, 1);
    expect((await resolve<CounterService>(tester, seen.single)).count, 5);
    expect(counterServiceCreated, 1);
  });

  testWidgets('fixed: scope injector disposed exactly once on removal', (tester) async {
    counterServiceCreated = 0;
    counterServiceDisposed = 0;
    late Injector scoped;
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([]),
      Rebuilder(
        key: key,
        builder: (_, gen) => gen >= 2
            ? const SizedBox()
            : InjectorScopeWidget(
                providers: [Provider.factory(CounterService)],
                child: InjectorProbe(onBuild: (i) => scoped = i),
              ),
      ),
    ));
    await resolve<CounterService>(tester, scoped);
    key.currentState!.rebuild();
    await tester.pump();
    key.currentState!.rebuild(); // removes the scope
    await tester.pump();
    await tester.pump();
    expect(counterServiceDisposed, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(counterServiceDisposed, 1);
  });

  testWidgets('fixed: InjectorScopeWidget ignores changed providers', (tester) async {
    late Injector scoped;
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([]),
      Rebuilder(
        key: key,
        builder: (_, gen) => InjectorScopeWidget(
          providers: [Provider.value(int, gen == 0 ? 1 : 2)],
          child: InjectorProbe(onBuild: (i) => scoped = i),
        ),
      ),
    ));
    expect(await resolve<int>(tester, scoped), 1);
    key.currentState!.rebuild();
    await tester.pump();
    expect(await resolve<int>(tester, scoped), 2); // fails: still 1
  });

  testWidgets('fixed: InjectorScopeWidget moved (GlobalKey) under another scope keeps old parent', (tester) async {
    late Injector scoped;
    final scopeKey = GlobalKey();
    final key = GlobalKey<RebuilderState>();
    Widget inner() => InjectorScopeWidget(
          key: scopeKey,
          providers: [Provider.value(int, 7)],
          child: InjectorProbe(onBuild: (i) => scoped = i),
        );
    await tester.pumpWidget(app(
      Injector([]),
      Rebuilder(
        key: key,
        builder: (_, gen) => Column(children: [
          InjectorScopeWidget(providers: [Provider.value(String, 'A')], child: gen == 0 ? inner() : const SizedBox()),
          InjectorScopeWidget(providers: [Provider.value(String, 'B')], child: gen == 0 ? const SizedBox() : inner()),
        ]),
      ),
    ));
    expect(await resolve<String>(tester, scoped), 'A');
    key.currentState!.rebuild();
    await tester.pump();
    expect(await resolve<String>(tester, scoped), 'B'); // fails: still 'A'
  });

  testWidgets('fixed: InjectorRootWidget ignores a new injector', (tester) async {
    late Injector seen;
    final first = Injector([Provider.value(String, 'first')]);
    final second = Injector([Provider.value(String, 'second')]);
    await tester.pumpWidget(app(first, InjectorProbe(onBuild: (i) => seen = i)));
    await tester.pumpWidget(app(second, InjectorProbe(onBuild: (i) => seen = i)));
    expect(identical(seen, second), isTrue); // fails: still `first`
  });

  // ---------- DependenciesBuilder ----------

  testWidgets('fixed: parent rebuild after ready flips DependenciesBuilder back to loading', (tester) async {
    final controller = StreamController<int>.broadcast();
    final vm = StreamVm(controller.stream);
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      Rebuilder(
        key: key,
        builder: (_, _) => DependenciesBuilder<StreamVm>(cleanViewModelInstance: vm, builder: stateText),
      ),
    ));
    await tester.pump();
    controller.add(1);
    await tester.pump();
    await tester.pump();
    expect(find.text('ready S:1'), findsOneWidget);
    key.currentState!.rebuild();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('loading'), findsNothing); // fails: shows 'loading' until next emission
    expect(find.text('ready S:1'), findsOneWidget);
    await controller.close();
  });

  testWidgets('fixed: parent rebuild re-listens single-subscription stream -> StateError', (tester) async {
    final controller = StreamController<int>();
    final vm = StreamVm(controller.stream);
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      Rebuilder(
        key: key,
        builder: (_, _) => DependenciesBuilder<StreamVm>(cleanViewModelInstance: vm, builder: stateText),
      ),
    ));
    await tester.pump();
    controller.add(1);
    await tester.pump();
    await tester.pump();
    expect(find.text('ready S:1'), findsOneWidget);
    key.currentState!.rebuild();
    await tester.pump();
    expect(tester.takeException(), isNull); // fails: Bad state: Stream has already been listened to
    await controller.close();
  });

  testWidgets('fixed: error flag stays true after stream recovers', (tester) async {
    final subject = PublishSubject<int>();
    final vm = StreamVm(subject.stream);
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      DependenciesBuilder<StreamVm>(cleanViewModelInstance: vm, builder: stateText),
    ));
    await tester.pump();
    subject.addError(Exception('boom'));
    await tester.pump();
    await tester.pump();
    expect(vm.error, isTrue);
    subject.add(3);
    await tester.pump();
    await tester.pump();
    expect(vm.ready, isTrue);
    expect(vm.error, isFalse); // fails: error is sticky while ready == true
    await subject.close();
  });

  testWidgets('fixed: dependency resolution failure shows error state', (tester) async {
    await tester.pumpWidget(app(
      Injector([]),
      DependenciesBuilder<NoStreamVm>(cleanViewModelInstance: MissingDepVm(), builder: stateText),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    // The ViewModel reads a dependency it never listed: that is reported, and
    // the builder shows the error state.
    expect(tester.takeException(), isNotNull);
    expect(find.text('error'), findsOneWidget);
  });

  testWidgets('fixed: empty streams list becomes ready', (tester) async {
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      DependenciesBuilder<NoStreamVm>(cleanViewModelInstance: NoStreamVm(), builder: stateText),
    ));
    await tester.pump();
    expect(find.text('ready S'), findsOneWidget);
  });

  testWidgets('fixed: stream subscription cancelled on dispose, late events harmless', (tester) async {
    var cancelled = 0;
    final controller = StreamController<int>.broadcast(onCancel: () => cancelled++);
    final vm = StreamVm(controller.stream);
    final completer = Completer<String>();
    // late-resolving dependency: unmount before it resolves
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      DependenciesBuilder<StreamVm>(cleanViewModelInstance: vm, builder: stateText),
    ));
    await tester.pump();
    controller.add(1);
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(cancelled, 1);
    controller.add(2);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    completer.complete('x');
    await controller.close();
  });

  testWidgets('fixed: throw in setPropertiesOnDependencyResolution is swallowed on next build -> ready with unset props', (tester) async {
    final vm = ThrowingVm();
    final key = GlobalKey<RebuilderState>();
    await tester.pumpWidget(app(
      Injector([Provider.value(String, 'S')]),
      Rebuilder(key: key, builder: (_, _) => DependenciesBuilder<NoStreamVm>(cleanViewModelInstance: vm, builder: stateText)),
    ));
    await tester.pump();
    expect(tester.takeException(), isA<StateError>());
    key.currentState!.rebuild();
    await tester.pump();
    expect(vm.ready, isFalse); // fails: ready == true, value never set
  });
}

class ThrowingVm extends NoStreamVm {
  @override
  void setPropertiesOnDependencyResolution(Dependencies d) => throw StateError('user bug');
}
