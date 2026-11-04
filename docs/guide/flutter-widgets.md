# Flutter widgets

The `complete_dependency_injector_flutter` package puts injectors into the widget tree, so any widget can get services from the nearest injector above it.

| Widget | Use it to |
|---|---|
| `InjectorRootWidget` | Put your root `Injector` at the top of the app. |
| `InjectorScopeWidget` | Create a child injector for one part of the tree, such as a screen, a dialog or one table. |
| `InjectorContainerWidget.of(context)` | Get the nearest injector yourself, when you aren't using `DependenciesBuilder`. |
| `DependenciesBuilder` | Resolve a ViewModel's dependencies and rebuild when its streams change. See [the demos](/demos/#the-basics). |

## InjectorRootWidget

Create the root injector, register your factories once, and wrap the whole app:

<<< @/demo/lib/main.dart#root{dart}

`InjectorRootWidget` goes above `MaterialApp` so that every route can see the injector. It keeps the injector for as long as the app runs and disposes it if the widget is ever removed.

## InjectorScopeWidget

`InjectorScopeWidget` creates a child injector with its own `providers`. Its parent is the nearest injector above it, which is either the root or another scope. Anything the scope doesn't provide is looked up in its parent.

Because each scope looks in itself first, a nested scope can **override** what its parent provides:

<<< @/demo/lib/demos/injector_widgets.dart#nested{dart}

<DemoFrame route="/widgets" :height="440" title="Injector widgets demo" />

Typical places for a scope:

- **A screen or route** that has its own state, such as a form or a wizard.
- **A repeated component**, like each of the [two tables](/use-cases/scoped-services) that need their own `TableManager`.
- **A test override**, where you wrap a widget in a scope that provides a fake with `Provider.value`.

## Reading the nearest injector

`DependenciesBuilder` finds the injector for you. When you need it directly, use `InjectorContainerWidget.of(context)`:

<<< @/demo/lib/demos/injector_widgets.dart#read-injector{dart}

`of` returns `null` when there is no injector above the widget, so make sure an `InjectorRootWidget` or `InjectorScopeWidget` is an ancestor.

## Scope lifecycle

- A scope creates its injector when it's first built and **keeps that injector across rebuilds**, so the instances it caches survive `setState` calls above it.
- When the scope **leaves the widget tree**, its injector is disposed. Every service it created that implements `InjectableWithDisposeInterface` gets `dispose()` called.
- To **start a scope fresh**, give it a new `key`. Flutter treats it as a new widget, so the old scope is disposed and a new one is built.

In the demo above, turn off **Show session scope** to remove a scope and watch its service get disposed:

<<< @/demo/lib/demos/injector_widgets.dart#lifecycle{dart}

<<< @/demo/lib/demos/injector_widgets.dart#dispose{dart}

::: warning Match the factory's scope to where you provide it
- A service you provide in an `InjectorScopeWidget` should use `scope: InjectableScope.instance` on its factory. Each scope then gets one instance, and disposes it when the scope leaves the tree.
- A service with the default `InjectableScope.root` should be provided at the root injector, so the whole app shares one instance.

Don't provide a root-scoped service only in a child scope. In the current version the child doesn't find the cached instance, so every request creates a new one. See [Scopes](./core-concepts#scopes-where-instances-live).
:::

::: info InjectorProviderWidget
`InjectorProviderWidget` is the building block both widgets use internally. You shouldn't need it directly; use `InjectorRootWidget` or `InjectorScopeWidget` instead.
:::
