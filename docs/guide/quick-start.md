# Quick start

This page builds a two-service program in about five minutes. You'll register services with an injector and then ask it for one, letting it build the dependencies for you.

## 1. Write some services

Every service needs two things:

- a **factory**, which says *this is how to build it*, and
- a **provider**, which says *an injector makes this service available*.

The recommended convention is to keep both on the service itself, as static `Factory` and `DefaultProvider` members. Your services stay plain Dart classes that don't extend or implement anything.

<<< @/snippets/lib/quick_start.dart#services{dart}

`DependencyDataBuilder.list([Logger])` tells the injector that `GreetingService` needs a `Logger`. The injector resolves it before calling the factory, and `deps.get<Logger>()` hands it over.

::: tip Lint note
`Factory` and `DefaultProvider` are capitalized on purpose so they read like part of the type. The `lints` package flags that with `non_constant_identifier_names`, so turn that rule off in `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    non_constant_identifier_names: ignore
```
:::

## 2. Create an injector

Registration now reads as a list of services:

<<< @/snippets/lib/quick_start.dart#injector{dart}

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
- [Flutter widgets](./flutter-widgets) shows how to put injectors into a Flutter widget tree.
- The [API reference](./api-reference) lists every class and method.
