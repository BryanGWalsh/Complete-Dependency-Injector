# Testing with fakes

Because services ask the injector for their dependencies instead of building them, a test can hand them a fake. The service under test runs its real code, and you check what it did to the fake.

The examples test the `CheckoutService` from [Interfaces and implementations](/use-cases/interfaces), which depends on an abstract `Analytics`.

## Write a fake

A fake implements the same interface and records what happened:

<<< @/snippets/test/testing_with_fakes_test.dart#fake{dart}

## Register the real factories once

Factories are global, and registering the same type twice fails an assert. Register them in `setUpAll`, once per test file. Each test file runs in its own isolate, so files don't affect each other.

<<< @/snippets/test/testing_with_fakes_test.dart#setup{dart}

## Provide the fake as a value

Build a new injector in each test. `Provider.value` hands out the fake as is, so it doesn't need a factory. Dispose the injector when the test ends.

<<< @/snippets/test/testing_with_fakes_test.dart#value{dart}

## Override in a child injector

To start from the app's real setup and change only one thing, create a child injector with `parent:`. Anything the child doesn't provide comes from the parent.

<<< @/snippets/test/testing_with_fakes_test.dart#child{dart}

The child provides `CheckoutService` as well as the fake. That matters: the injector that provides a type builds its instance. If only `Analytics` is overridden, asking the child for `CheckoutService` returns the root's instance, which was built with the real `Analytics`:

<<< @/snippets/test/testing_with_fakes_test.dart#missing{dart}

## Widget tests

In a Flutter widget test, wrap the widget in an `InjectorRootWidget` whose injector provides the fakes:

```dart
await tester.pumpWidget(
  InjectorRootWidget(
    injector: Injector([
      Provider.value(Analytics, FakeAnalytics()),
      CheckoutService.DefaultProvider,
    ]),
    child: const MaterialApp(home: CheckoutScreen()),
  ),
);
```

The [demo app's tests](https://github.com/BryanGWalsh/Complete-Dependency-Injector/blob/main/docs/demo/test/demos_test.dart) use this pattern for every demo.

## Replacing a factory

If a test needs a different *factory* for a type, for example to count how often it's built, create the injector with `InjectorDebugOptions(allowFactoryReplacement: true)` and register the new factory. Factories are global, so the replacement lasts for the rest of the test file. Prefer `Provider.value` or a child injector when they're enough.
