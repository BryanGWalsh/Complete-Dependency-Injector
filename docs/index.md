---
layout: home

hero:
  name: Complete Dependency Injector
  text: Dependency injection for Dart and Flutter
  tagline: Hierarchical scopes, async services and a boilerplate-free ViewModel pattern, in two small packages.
  actions:
    - theme: brand
      text: Quick start
      link: /guide/quick-start
    - theme: alt
      text: Core concepts
      link: /guide/core-concepts
    - theme: alt
      text: API reference
      link: /guide/api-reference

features:
  - title: Hierarchical injection
    details: Nest injectors to match your app's structure. Children inherit their parent's services and can override or add their own.
  - title: Async from the start
    details: Factories can return a Future, and services can finish setting up after construction. Anything that depends on them waits automatically.
  - title: Scoped singletons
    details: Choose per factory whether an instance is shared app-wide or created once per scope, such as one per screen.
  - title: Flutter widgets and ViewModels
    details: Put injectors in the widget tree and drive UI from service streams with built-in loading, ready and error states.
---

## Two packages

| Package | Use it for |
|---|---|
| [`complete_dependency_injector`](https://pub.dev/packages/complete_dependency_injector) | The injector itself. Pure Dart, works anywhere. |
| [`complete_dependency_injector_flutter`](https://pub.dev/packages/complete_dependency_injector_flutter) | Widgets that place injectors in the widget tree, plus the `DependenciesBuilder` ViewModel pattern. |

## At a glance

<<< @/snippets/lib/quick_start.dart#injector{dart}

<<< @/snippets/lib/quick_start.dart#use{dart}
