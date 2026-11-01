# Core concepts

Complete Dependency Injector uses three building blocks: **providers**, **factories** and **injectors**. If you've used Angular's injector, the model will feel familiar.

## Injectors

An `Injector` holds a list of providers and caches the instances it creates. Injectors can have a parent. When an injector doesn't provide something itself, it asks its parent, and so on up to the root.

## Providers: what is available

A provider maps a **token** to a way of getting a value. Usually the token is a class type.

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

- `InjectableFactory.withoutDependencies<T>(() => ...)` is for types with no dependencies.
- `InjectableFactory.withDependencies<T>(dependencyData, (deps) => ...)` declares dependencies with a `DependencyDataBuilder`. The injector resolves them first and passes them in as `deps`.

A factory can return a `Future<T>` when construction is asynchronous. Anything that depends on that type waits for it.

## Tokens

When a type alone isn't enough, for example a `String` setting, use an `InjectorToken`:

<<< @/snippets/lib/core_concepts.dart#tokens{dart}

Then provide it with `Provider.value(apiBaseUrl, '...')` and read it with `injector.getService<String>(apiBaseUrl)`.

## Scopes: where instances live

Each factory has an `InjectableScope`:

- `InjectableScope.root` (the default) caches the instance in the root injector, so the whole app shares one.
- `InjectableScope.instance` caches the instance in the injector that provides it. Two child injectors that both provide the type each get their own.

<<< @/snippets/lib/core_concepts.dart#hierarchy{dart}

In Flutter, this is how you give each screen its own state while sharing app-wide services.

## Lifecycle

- Services that implement `InjectableWithDisposeInterface` get `dispose()` called when their injector is disposed.
- Services that use `InjectableWithReadyMixin` can finish asynchronous setup after construction and call `setInjectableReadyResult(true)` when ready. Dependents wait until then.

## Debug options

`InjectorDebugOptions` controls how strict the injector is, for example whether a factory can be registered twice. The defaults are strict and suit most apps.
