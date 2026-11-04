# Demos

Every demo is a screen in one small Flutter web app, built from [`docs/demo`](https://github.com/BryanGWalsh/Complete-Dependency-Injector/tree/main/docs/demo) and running on this site. The code samples in the guides are imported from the same files, so what you read is what's running.

<a href="/demo/" target="_self">Open the demo app ↗</a>

## The basics

A `CounterService` provided at the root keeps its count in a stream. A ViewModel observes the stream, and `DependenciesBuilder` rebuilds when it changes.

<DemoFrame route="/basics" :height="360" title="Basics demo" />

::: details Show the code
<<< @/demo/lib/demos/basics.dart#service{dart}

<<< @/demo/lib/demos/basics.dart#view-model{dart}

<<< @/demo/lib/demos/basics.dart#widget{dart}
:::

## Injector widgets

Nested `InjectorScopeWidget`s, a scope overriding its parent, and a scope disposing its service when it leaves the tree. [Read the guide](/guide/flutter-widgets).

<DemoFrame route="/widgets" :height="440" title="Injector widgets demo" />

## Async services

A service that takes two seconds to open, and a screen that shows a loading state until it's ready. [Read the guide](/use-cases/async-services).

<DemoFrame route="/async" :height="420" title="Async services demo" />

## Scoped services

Two tables, each with its own `TableManager`, sharing one `ProductRepository`. [Read the guide](/use-cases/scoped-services).

<DemoFrame route="/tables" :height="420" title="Scoped services demo" />
