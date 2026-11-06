## 2.0.3

- Fixed: two injectors building the same factory at the same time could hand each other's dependencies to the new instance, and a `Dependencies` object a service kept could be overwritten by a later resolution. Each resolution now works on its own copy.
- Fixed: a factory that failed once kept failing, because the failed future was cached. The next request now builds the service again.
- Fixed: `dispose()` threw the error of any factory that had failed earlier, instead of disposing the services that were created.
- Fixed: a service reached through an alias (`aliasTokens`, `Provider.existing`) in the same injector was disposed twice.
- Fixed: `setInjectableReadyResult(false)` was ignored and the service was handed out anyway. It now fails resolution with an `InjectorError`.
- Fixed: a dependency cycle overflowed the stack and crashed the isolate. It now fails with an `InjectorError` that names the cycle.
- Added: `InjectableWithReadyMixin.setInjectableReadyError(error, [stackTrace])`, so async setup that fails can fail resolution instead of leaving it waiting forever.

## 2.0.2

- Fixed: an optional dependency (any entry in `DependencyDataBuilder.list`, or `namedOptional`) that nothing provides now resolves to `null` instead of crashing.
- Fixed: `getServiceOrNull` now returns `null` when nothing provides the type, instead of throwing.
- Fixed: an error thrown while building a dependency deeper in the graph now fails the `getService` future, instead of leaving it waiting forever.
- Fixed: a dependency cycle (`A` needs `B` needs `A`, or aliases pointing at each other) overflowed the stack and could crash the isolate. It now fails with an `InjectorError` that names the cycle.
- Fixed: two injectors resolving the same factory or `DependencyData` at the same time shared one set of results, so one scope could be built with another scope's dependencies. Each resolution now fills its own copy.
- Fixed: `getService<Injector>()`, and factories that list `Injector` as a dependency, threw "No provider found". They now get the closest injector.
- Fixed: subclasses of `InjectorToken` threw a cast error in `getService` and `DependencyDataBuilder`.
- Fixed: after an optional lookup of an alias whose target nothing provides, later required lookups of that alias returned `null` instead of throwing.

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
