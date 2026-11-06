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
