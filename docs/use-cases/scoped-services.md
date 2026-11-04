# Scoped services

Some services hold state that belongs to one part of the screen. Picture a dashboard with two product tables. Each table needs its own sort order and selection, but both read from the same data source.

With Complete Dependency Injector, where you provide a service decides how many there are:

- `ProductRepository` is provided at the **root**, so the whole app shares one.
- `TableManager` is provided by an `InjectorScopeWidget` around each table, so each table gets its own.

Try it: sort or select rows in one table and the other doesn't change. The `#` number in each title is that table's `TableManager` instance.

<DemoFrame route="/tables" :height="420" title="Scoped services demo" />

## The shared service

<<< @/demo/lib/demos/scoped_tables.dart#repository{dart}

## The scoped service

`TableManager` holds the table's state itself, with one `BehaviorSubject` stream per value (rows, sort column, sort direction and selection), so the UI can react to each one. Nothing in its factory says it's per-table. That comes from where it's provided.

<<< @/demo/lib/demos/scoped_tables.dart#manager{dart}

## Give each table its own scope

Each `InjectorScopeWidget` creates a child injector that provides `TableManager`. When the table's ViewModel asks for a `TableManager`, it gets the one from its nearest scope. Asking for `ProductRepository` walks up to the root.

<<< @/demo/lib/demos/scoped_tables.dart#widgets{dart}

The ViewModel observes those streams and copies the latest values into its own properties for the UI. It doesn't know which scope it's in:

<<< @/demo/lib/demos/scoped_tables.dart#view-model{dart}

## Register once at the root

Factories are global. Register them all once at startup, and provide only the app-wide services at the root:

<<< @/demo/lib/main.dart#root{dart}

When a table's scope leaves the widget tree, its injector is disposed. That calls `dispose()` on its `TableManager`, which closes the stream.
