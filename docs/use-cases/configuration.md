# Configuration and environments

Settings such as an API base URL, a timeout or a feature flag aren't services, but the code that needs them is. Provide them as values, and every service gets them the same way it gets any other dependency. Changing environment then means changing one list of providers.

## Name each plain value with a token

A `String` or `Duration` can't be its own token, because the app may have many of them. Give each one an `InjectorToken`:

<<< @/snippets/lib/configuration.dart#tokens{dart}

`InjectorToken.fromString` uses the name you give it, so two tokens with the same name are the same token. Use `InjectorToken.fromCounter()` when you want one that can never collide.

## Group related settings in a class

Settings that belong together can be one class. The class is its own token, so it needs no `InjectorToken`:

<<< @/snippets/lib/configuration.dart#typed{dart}

## Read settings in a factory

List the tokens as dependencies and read each one with `deps.get<T>(token)`. Use `deps.getOptional<T>(token)` for a setting that some environments leave out. It returns `null` when nothing provides it.

<<< @/snippets/lib/configuration.dart#consumer{dart}

::: info
Optional dependencies that nothing provides need `complete_dependency_injector` 2.0.2 or later.
:::

## One provider list per environment

Keep each environment's settings in one function:

<<< @/snippets/lib/configuration.dart#environments{dart}

## Build the root from it

Spread the chosen environment into the root injector, next to the services:

<<< @/snippets/lib/configuration.dart#root{dart}

Register the factories once at startup, as usual:

<<< @/snippets/lib/configuration.dart#register{dart}

In Flutter, do the same in `main()` and pass the injector to `InjectorRootWidget`. Pick the environment however your app already does, for example with `--dart-define=ENV=production` and `String.fromEnvironment('ENV')`.

## Override a setting for one part of the app

Settings resolve like any other provider, so a child injector or `InjectorScopeWidget` can provide a different value for one token. As with services, a consumer sees the override only if it's provided at or below that scope.
