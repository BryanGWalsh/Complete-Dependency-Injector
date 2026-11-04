import 'package:cdi_demo/demos/async_loading.dart';
import 'package:cdi_demo/demos/basics.dart';
import 'package:cdi_demo/demos/injector_widgets.dart';
import 'package:cdi_demo/demos/scoped_tables.dart';
import 'package:cdi_demo/main.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => InjectorRootWidget(
      injector: createRootInjector(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('basics: increment updates the count', (tester) async {
    await tester.pumpWidget(host(const BasicsDemo()));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('Increment'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('async: shows loading until the database is ready', (tester) async {
    SlowDatabase.openDelay = const Duration(milliseconds: 500);
    await tester.pumpWidget(host(const AsyncLoadingDemo()));
    await tester.pump();
    expect(find.text('Opening database...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Grace Hopper'), findsOneWidget);

    // Reload goes through the service, so no StatefulWidget is needed.
    await tester.tap(find.text('Reload'));
    await tester.pump();
    expect(find.text('Opening database...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Grace Hopper'), findsOneWidget);
  });

  testWidgets('tables: each table has its own TableManager', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const ScopedTablesDemo()));
    await tester.pumpAndSettle();

    final managerA = find.textContaining('Table A · TableManager #');
    final managerB = find.textContaining('Table B · TableManager #');
    expect(managerA, findsOneWidget);
    expect(managerB, findsOneWidget);
    expect(
      tester.widget<Text>(managerA).data!.split('#').last,
      isNot(tester.widget<Text>(managerB).data!.split('#').last),
    );

    // Select a row in Table A only.
    await tester.tap(find.descendant(of: find.byKey(const Key('Table A-table')), matching: find.text('Monitor')));
    await tester.pumpAndSettle();
    expect(find.text('Selected: Monitor'), findsOneWidget);
    expect(find.text('Selected: none'), findsOneWidget);
  });

  testWidgets('widgets: nested scopes override, removed scopes dispose', (tester) async {
    await tester.pumpWidget(host(const InjectorWidgetsDemo()));
    await tester.pumpAndSettle();
    expect(find.text('Hello from the outer scope'), findsOneWidget);
    expect(find.text('Hello from the inner scope'), findsOneWidget);
    expect(find.text('ScopeSession is alive'), findsOneWidget);

    final before = ScopeSession.disposedCount.value;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('ScopeSession is alive'), findsNothing);
    expect(ScopeSession.disposedCount.value, before + 1);
  });
}
