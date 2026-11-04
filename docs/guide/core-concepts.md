# Core concepts

Complete Dependency Injector uses three building blocks: **providers**, **factories** and **injectors**. If you've used Angular's injector, the model will feel familiar.

## Injectors

An `Injector` holds a list of providers and caches the instances it creates. Injectors can have a parent. When an injector doesn't provide something itself, it asks its parent, and so on up to the root.

## Providers: what is available

A provider maps a **token** to a way of getting a value. Usually the token is a class type. Services carry their usual provider as a static `DefaultProvider` (see [the convention below](#recommended-convention)); one-off values are written inline.

<<< @/snippets/lib/core_concepts.dart#providers{dart}

| Provider | What it does | Needs a factory? |
|---|---|---|
| `Provider(T)` | Build `T` with its registered factory. | Yes |
| `Provider.value(token, value)` | Always return `value`. | No |
| `Provider.existing(token, other)` | Return whatever `other` resolves to, so two tokens share one instance. | No |
| `Provider.factory(token, fromDerived: Impl)` | Build `Impl` with its factory and return it when `token` is asked for. Good for interfaces. | Yes, for `Impl` |

Every provider also accepts `aliasTokens`, a list of extra tokens that resolve to the same instance.

## Factories: how to build it

A factory describes how to construct one type: what it depends on, and the function that builds it. Factories are registered once and shared by every injector in the hierarchy.

<<< @/snippets/lib/core_concepts.dart#factories{dart}

Each service exposes its factory as a static `Factory`, so registration is just a list.

- `InjectableFactory.withoutDependencies<T>(() => ...)` is for types with no dependencies.
- `InjectableFactory.withDependencies<T>(dependencyData, (deps) => ...)` declares dependencies with a `DependencyDataBuilder`. The injector resolves them first and passes them in as `deps`.

When a service needs asynchronous setup, give it `InjectableWithReadyMixin`. The injector waits for it to be ready before handing it out or building anything that depends on it. See [Async services](/use-cases/async-services).

## Tokens

When a type alone isn't enough, for example a `String` setting, use an `InjectorToken`:

<<< @/snippets/lib/core_concepts.dart#tokens{dart}

Then provide it with `Provider.value(apiBaseUrl, '...')` and read it with `injector.getService<String>(apiBaseUrl)`.

## Scopes: where instances live

An instance lives in **the injector that provides it**. That injector creates it the first time it's asked for, caches it, and disposes it when the injector is disposed.

- Provide a service at the **root** and the whole app shares one instance.
- Provide it in a **child** injector and that child gets its own. Two children that both provide the type each get their own instance.
- A child that provides a type its parent also provides **overrides** it. The child gets its own instance, and the parent keeps its own.

Factories don't say where an instance lives. They only describe how to build it, so the same factory works for an app-wide service and a per-screen one.

<<< @/snippets/lib/core_concepts.dart#per-child{dart}

<<< @/snippets/lib/core_concepts.dart#hierarchy{dart}

In Flutter, this is how you give each screen its own state while sharing app-wide services.

## Recommended convention

Give every service a static `Factory` and `DefaultProvider`, built with the `InjectableFactory` and `Provider` helpers:

<<< @/snippets/lib/core_concepts.dart#convention{dart}

Then registration never contains construction logic:

```dart
injector.registerFactories([ApiClient.Factory, SessionState.Factory]);
final child = Injector([SessionState.DefaultProvider], parent: injector);
```

This keeps everything about a service in one file. For an interface, put the `DefaultProvider` on the interface and the `Factory` on the implementation:

<<< @/snippets/lib/core_concepts.dart#interface{dart}

The member is called `DefaultProvider` rather than `Provider` because a static named `Provider` would hide the `Provider` class inside the service. "Default" also signals that a different provider, such as a `Provider.value` fake in a test, can replace it.

## Lifecycle

- Services that implement `InjectableWithDisposeInterface` get `dispose()` called when their injector is disposed.
- Services that use `InjectableWithReadyMixin` can finish asynchronous setup after construction and call `setInjectableReadyResult(true)` when ready. Dependents wait until then.

## Debug options

`InjectorDebugOptions` controls how strict the injector is, for example whether a factory can be registered twice. The defaults are strict and suit most apps.
