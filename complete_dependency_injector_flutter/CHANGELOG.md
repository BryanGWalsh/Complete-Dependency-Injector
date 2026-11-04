## 2.0.0

- Requires `complete_dependency_injector` 2.0.0, where the injector that provides a service owns its instance. A service provided by an `InjectorScopeWidget` gets one instance per scope, disposed with the scope. You no longer need `scope: InjectableScope.instance` on its factory (that option was removed).

## 1.0.1

- Added docs site.
- Resolved all analyzer infos: `DependenciesBuilderViewModelStates` values are now lowerCamelCase and ViewModel base methods declare `void` return types.
- `InjectorProviderWidget` now passes its current `child` on rebuild instead of the child from its first build.

## 1.0.0

- Initial version.
