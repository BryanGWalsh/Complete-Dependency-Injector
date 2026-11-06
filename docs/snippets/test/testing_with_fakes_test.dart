// Samples for docs/use-cases/testing.md.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_docs_snippets/interfaces.dart';
import 'package:test/test.dart';

// #region fake
/// Records events instead of sending them.
class FakeAnalytics implements Analytics {
  final List<String> events = [];

  @override
  void track(String event) => events.add(event);
}
// #endregion fake

void main() {
  // #region setup
  // Factories are global, so register the real ones once per test file.
  setUpAll(() {
    Injector([]).registerFactories([
      ConsoleAnalytics.Factory,
      CheckoutService.Factory,
    ]);
  });
  // #endregion setup

  // #region value
  test('placing an order tracks an event', () async {
    final fake = FakeAnalytics();
    // A fresh injector per test. The fake is a ready-made value, so it needs no factory.
    final injector = Injector([
      Provider.value(Analytics, fake),
      CheckoutService.DefaultProvider, // the real service under test
    ]);
    addTearDown(injector.dispose);

    final checkout = await injector.getService<CheckoutService>();
    checkout.placeOrder();

    expect(fake.events, ['order_placed']);
  });
  // #endregion value

  // #region child
  test('a child injector overrides one service and keeps the rest', () async {
    // The app's real setup.
    final appRoot = Injector([
      Analytics.DefaultProvider,
      CheckoutService.DefaultProvider,
    ]);
    addTearDown(appRoot.dispose);

    // Provide the fake, and the service that should see it, closer to the test.
    final fake = FakeAnalytics();
    final testScope = Injector([
      Provider.value(Analytics, fake),
      CheckoutService.DefaultProvider,
    ], parent: appRoot);
    addTearDown(testScope.dispose);

    (await testScope.getService<CheckoutService>()).placeOrder();
    expect(fake.events, ['order_placed']);

    // The app root still has the real implementation.
    expect(await appRoot.getService<Analytics>(), isA<ConsoleAnalytics>());
  });
  // #endregion child

  // #region missing
  test('the root instance is not affected by a child override', () async {
    final appRoot = Injector([
      Analytics.DefaultProvider,
      CheckoutService.DefaultProvider,
    ]);
    addTearDown(appRoot.dispose);

    // Only Analytics is overridden. CheckoutService still lives at the root,
    // so it was built with the root's Analytics.
    final testScope = Injector([Provider.value(Analytics, FakeAnalytics())], parent: appRoot);
    addTearDown(testScope.dispose);

    final fromChild = await testScope.getService<CheckoutService>();
    final fromRoot = await appRoot.getService<CheckoutService>();
    expect(identical(fromChild, fromRoot), isTrue);
  });
  // #endregion missing
}
