# Async services

Some services can't be used the moment they're constructed. A database has to open, a config file has to load, a socket has to connect. With Complete Dependency Injector, the service announces when it's ready, and the injector won't hand it out or build anything that depends on it until then.

## Mark the service as ready-aware

Add `InjectableWithReadyMixin`, start the async work in the constructor, and call `setInjectableReadyResult(true)` when it's done.

<<< @/snippets/lib/async_services.dart#database{dart}

## Depend on it like any other service

`UserRepository` doesn't know or care that `Database` is asynchronous. It just takes one in its constructor.

<<< @/snippets/lib/async_services.dart#repository{dart}

## Ask for it

`getService` completes only once the whole chain is ready:

<<< @/snippets/lib/async_services.dart#use{dart}

The repository is created after the database has opened, so it can use it straight away.

## In Flutter: loading states for free

`DependenciesBuilder` reports `loading` until every dependency of the ViewModel is ready, so a slow service turns into a spinner with no extra code. Press **Reload** to load the data again.

<DemoFrame route="/async" :height="420" title="Async services demo" />

The service:

<<< @/demo/lib/demos/async_loading.dart#service{dart}

The ViewModel and screen:

<<< @/demo/lib/demos/async_loading.dart#view-model{dart}

<<< @/demo/lib/demos/async_loading.dart#widget{dart}

The screen is a `StatelessWidget`. The first load is covered by the ready mixin, which drives `loading`. After that, reloading is just more state in the service's stream: `users` is `null` while loading, and `DependenciesBuilder` rebuilds when it changes. Keep state like this in services and streams, and you rarely need a `StatefulWidget`.

::: tip Why not return a Future from the factory?
A factory's creator function must return the service type itself, so `() => Database.open()` (a `Future<Database>`) doesn't type-check. Use `InjectableWithReadyMixin` for async setup.
:::
