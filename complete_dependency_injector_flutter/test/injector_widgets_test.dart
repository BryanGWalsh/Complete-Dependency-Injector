import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';

class AsyncText extends StatelessWidget {
  final Object type;
  final String label;
  const AsyncText({super.key, required this.type, required this.label});

  @override
  Widget build(BuildContext context) {
    final injector = InjectorContainerWidget.of(context)!.injector;
    return FutureBuilder(
      future: injector.getServiceOrNull(type),
      builder: (context, snapshot) {
        return Text("$label: ${snapshot.data}", textDirection: TextDirection.ltr);
      },
    );
  }
}

void main() {
  testWidgets('InjectorScopeWidget creates a child scope and resolves', (WidgetTester tester) async {
    final rootInjector = Injector([
      Provider.value(String, "RootValue"),
    ]);

    await tester.pumpWidget(
      InjectorRootWidget(
        injector: rootInjector,
        child: MaterialApp(
          home: InjectorScopeWidget(
            providers: [
              Provider.value(int, 42),
            ],
            child: const Column(
              children: [
                AsyncText(type: String, label: "String"),
                AsyncText(type: int, label: "Int"),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("String: RootValue"), findsOneWidget);
    expect(find.text("Int: 42"), findsOneWidget);
  });

  testWidgets('InjectorScopeWidget can override parent providers', (WidgetTester tester) async {
    final rootInjector = Injector([
      Provider.value(String, "RootValue"),
    ]);

    await tester.pumpWidget(
      InjectorRootWidget(
        injector: rootInjector,
        child: MaterialApp(
          home: InjectorScopeWidget(
            providers: [
              Provider.value(String, "ChildValue"),
            ],
            child: const AsyncText(type: String, label: "Value"),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Value: ChildValue"), findsOneWidget);
    expect(find.text("Value: RootValue"), findsNothing);
  });
}
