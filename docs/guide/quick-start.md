# Quick start

This page builds a two-service program in about five minutes. You'll register services with an injector and then ask it for one, letting it build the dependencies for you.

## 1. Write some services

Plain Dart classes. Nothing needs to extend or implement anything.

<<< @/snippets/lib/quick_start.dart#services{dart}

## 2. Create an injector

Every service needs two things:

- a **provider**, which says *this injector makes the service available*, and
- a **factory**, which says *this is how to build it*.

<<< @/snippets/lib/quick_start.dart#injector{dart}

`DependencyDataBuilder.list([Logger])` tells the injector that `GreetingService` needs a `Logger`. The injector resolves it before calling your factory, and `deps.get<Logger>()` hands it over.

## 3. Ask for a service

`getService` returns a `Future`, because any service in the chain may be asynchronous.

<<< @/snippets/lib/quick_start.dart#use{dart}

The `Logger` is built first, then the `GreetingService`. Both are cached in the injector, so the next `getService` call returns the same instances.

## The whole program

::: details Show full source
<<< @/snippets/lib/quick_start.dart#all{dart}
:::

## Where to go next

- [Core concepts](./core-concepts) explains providers, factories, tokens and scopes in more depth.
- The [API reference](./api-reference) lists every class and method.
