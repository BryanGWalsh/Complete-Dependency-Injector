# Interfaces and implementations

Code that asks for an abstract type doesn't care which class it gets. That lets you choose the implementation in one place: a real one in the app, a fake in tests, or a different one in one part of the screen.

Try it: both lists below use the same widget, which asks for a `PriceFormatter`. The root provides `UsdFormatter`. The second list sits in a scope that provides `EurFormatter` instead.

<DemoFrame route="/interfaces" :height="300" title="Interfaces demo" />

## Put the provider on the interface

Give the abstract class a `DefaultProvider` built with `Provider.factory(Interface, fromDerived: Implementation)`. Asking for the interface then builds the implementation with its factory.

<<< @/snippets/lib/interfaces.dart#interface{dart}

## Put the factory on the implementation

Only concrete classes have factories. The interface never needs one.

<<< @/snippets/lib/interfaces.dart#implementation{dart}

## Depend on the interface

Consumers list the interface as their dependency, so they never import or name the implementation.

<<< @/snippets/lib/interfaces.dart#consumer{dart}

## Provide and use it

Register the implementation's factory, then provide the interface's `DefaultProvider`. The interface and the implementation resolve to the **same instance**, because `fromDerived` provides the implementation and points the interface at it.

<<< @/snippets/lib/interfaces.dart#use{dart}

## Swap the implementation in one part of the app

A child injector, or an `InjectorScopeWidget` in Flutter, can provide the same interface again with a different implementation. Everything below it gets the new one, and everything else keeps the default. This is the code behind the demo above:

<<< @/demo/lib/demos/interfaces.dart#interface{dart}

<<< @/demo/lib/demos/interfaces.dart#widgets{dart}

::: tip Provide consumers where they should see the swap
The injector that provides a type builds its instance, using what *it* can see. If `CheckoutService` is provided at the root, it is built with the root's `Analytics`, even when a child asks for it. To have a child's `CheckoutService` use the child's `Analytics`, provide both in the child. [Testing with fakes](/use-cases/testing#override-in-a-child-injector) shows this.
:::

## One class in several roles

When one class implements several interfaces, use `aliasTokens` to reach a single instance under each of them:

<<< @/snippets/lib/interfaces.dart#multi{dart}

Writing through `SettingsWriter` and reading through `SettingsReader` uses the same `MemorySettings`, as the `use` sample above shows.

## Which provider to use

| You want | Use |
| --- | --- |
| An interface built by an implementation's factory | `Provider.factory(Interface, fromDerived: Impl)` |
| One instance under several tokens | `Provider.factory(Impl, aliasTokens: [RoleA, RoleB])` |
| A token that points at another token already provided | `Provider.existing(Interface, Impl)` |
| A ready-made object, such as a fake | `Provider.value(Interface, instance)` |
