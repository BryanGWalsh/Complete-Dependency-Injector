## 2.0.3

Bug fixes from a full review of the library. Each fix has a regression test.

**Resolution**
- Fixed: an optional dependency, or `getServiceOrNull`, for a type that is provided but has no registered factory now resolves to `null` instead of throwing.
- Fixed: two injectors building the same factory at the same time could hand each other's dependencies to the new instance. Each resolution now fills its own copy of the `DependencyData`.
- Fixed: a factory that failed once kept failing, because the failed future was cached. The next request now builds the service again.
- Fixed: a dependency cycle, or aliases pointing at each other, overflowed the stack. It now fails with an `InjectorError` that names the cycle.
- Fixed: after an optional lookup of an alias whose target nothing provides, later required lookups returned `null` instead of throwing.
- Fixed: `getService<Injector>()`, and factories that list `Injector` as a dependency, threw "No provider found". They now get the closest injector, or the one you provide with `Provider.value(Injector, ...)`.
- Fixed: subclasses of `InjectorToken` threw a cast error in `getService` and `DependencyDataBuilder`.
- Fixed: `Provider(Foo)` together with `Provider.factory(IFoo, fromDerived: Foo)`, or two interfaces both using `fromDerived: Foo`, were rejected as duplicate providers.
- Fixed: `DependencyDataBuilder().named(...)` asserted unless both `required` and `optional` were passed, and the `namedRequired` and `namedOptional` factories ignored `safety`.

**Async readiness**
- Changed: `setInjectableReadyResult(false)` now fails resolution with an `InjectorError`. It used to hand the service out anyway.
- Added: `InjectableWithReadyMixin.setInjectableReadyError(error, [stackTrace])`, so async setup that fails can fail resolution instead of leaving it waiting forever.

**Disposal**
- Fixed: a service reached through `fromDerived` or `aliasTokens` was disposed once per token. Each instance is now disposed exactly once.
- Fixed: `dispose()` threw the error of any factory that had failed earlier.
- Fixed: `dispose()` never completed while a service was still waiting to become ready. It no longer waits; a service that finishes creating after its injector was disposed is disposed straight away.
- Fixed: disposing a parent injector now disposes its child injectors first.
- Fixed: calling `dispose()` twice disposed everything twice. A second call now returns the first call's future.
- Changed: using an injector after `dispose()`, or creating a child of a disposed injector, throws an `InjectorError` instead of handing out disposed instances.
- Changed: services are disposed one at a time, in reverse creation order, so a service is disposed before the services it depends on. `dispose()` callbacks run asynchronously, never inside the call to `Injector.dispose()`.

**Errors**
- Fixed: `InjectorError.toString()` printed "Instance of 'InjectorError'". It now includes the message.
- Improved: "No provider found" and the missing-factory error name the type (for example `ApiClient`) instead of an internal token string, and the missing-factory error says to register the factory.

## 2.0.2

- Fixed: an optional dependency (any entry in `DependencyDataBuilder.list`, or `namedOptional`) that nothing provides now resolves to `null` instead of crashing.
- Fixed: `getServiceOrNull` now returns `null` when nothing provides the type, instead of throwing.
- Fixed: an error thrown while building a dependency deeper in the graph now fails the `getService` future, instead of leaving it waiting forever.

## 2.0.1

- README install snippet now shows `^2.0.0`.

## 2.0.0

**Breaking:** where a service is provided now decides where its instance lives.

- The injector that provides a type creates, caches and disposes its instance. Provide a service at the root for one app-wide instance, or in a child injector for one instance per child.
- Removed `InjectableScope` and the `scope:` parameter of `InjectableFactory.withDependencies` and `InjectableFactory.withoutDependencies`. To migrate, delete `scope:` arguments. Services that used `InjectableScope.instance` already behave the same. Services that used the default root scope keep one app-wide instance as long as they're provided at the root.
- Fixed: a root-scoped factory provided only in a child injector created a new instance on every request.
- Removed `InjectorDebugOptions.errorOnProviderInstanceScopeMismatch`, which was never used.

## 1.0.1

- Added docs site.
- Resolved all analyzer warnings and infos (removed an unused token field, added missing type annotations).

## 1.0.0

- Initial version.
