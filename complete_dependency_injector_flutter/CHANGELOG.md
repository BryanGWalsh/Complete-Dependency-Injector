## 2.0.2

- Requires `complete_dependency_injector` 2.0.3.
- Fixed: when a parent of `DependenciesBuilder` rebuilt, it listened to the ViewModel's streams again. A ready ViewModel dropped back to `loading` until the next emission (forever, for a stream that doesn't replay its latest value), and a single-subscription stream threw `Bad state: Stream has already been listened to`.
- Fixed: a ViewModel created inside a parent's `build` (as in the README) was replaced on every parent rebuild and lost its state. `DependenciesBuilder` now keeps the first ViewModel it is given; give it a new `key` to start over.
- Fixed: a ViewModel's `error` stayed `true` after its streams recovered.
- Fixed: two `DependenciesBuilder`s in different scopes whose ViewModels share one `DependencyData` both got the instances from the last scope to resolve.

## 2.0.1

- README install snippet now shows `^2.0.0`.

## 2.0.0

- Requires `complete_dependency_injector` 2.0.0, where the injector that provides a service owns its instance. A service provided by an `InjectorScopeWidget` gets one instance per scope, disposed with the scope. You no longer need `scope: InjectableScope.instance` on its factory (that option was removed).

## 1.0.1

- Added docs site.
- Resolved all analyzer infos: `DependenciesBuilderViewModelStates` values are now lowerCamelCase and ViewModel base methods declare `void` return types.
- `InjectorProviderWidget` now passes its current `child` on rebuild instead of the child from its first build.

## 1.0.0

- Initial version.
