## 2.0.3

- Requires `complete_dependency_injector` 2.0.3.
- Fixed: when a parent of `DependenciesBuilder` rebuilt, it listened to the ViewModel's streams again. A ready ViewModel dropped back to `loading` until the next emission, and a single-subscription stream threw `Bad state: Stream has already been listened to`.
- Fixed: a ViewModel created inside a parent's `build` was replaced on every parent rebuild and lost its state. `DependenciesBuilder` now keeps the first ViewModel it is given; give it a new `key` to start over.
- Fixed: a ViewModel's `error` stayed `true` after its streams recovered.
- Fixed: if `setPropertiesOnDependencyResolution` threw, the next rebuild reported the ViewModel as ready with its properties unset. It now stays in the error state, and the exception is reported through `FlutterError`.
- Fixed: `InjectorScopeWidget` created a throwaway `Injector` on every build. It now creates one, and replaces it (disposing the old one) only when its `providers` change or it moves under a different parent injector. A changed `providers` list used to be ignored.
- Fixed: an `InjectorScopeWidget` moved with a `GlobalKey` under a different parent kept using the old parent injector.
- Fixed: `InjectorRootWidget` ignored a new `injector`. It now switches to the new one and disposes the old one.

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
