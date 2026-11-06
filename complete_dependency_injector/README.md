# complete-dependency-injector

A lightweight, fast, and elegant dependency injection solution for Dart and Flutter. 

**[Documentation, tutorials and live demos →](https://complete-dependency-injector.bryangwalsh.com)**

- [Quick start](https://complete-dependency-injector.bryangwalsh.com/guide/quick-start)
- [Use cases](https://complete-dependency-injector.bryangwalsh.com/use-cases/async-services): async services, scoped services
- [Live Flutter web demos](https://complete-dependency-injector.bryangwalsh.com/demos/)
- [API reference](https://complete-dependency-injector.bryangwalsh.com/guide/api-reference)

`complete-dependency-injector` consists of two packages:
- **`complete_dependency_injector`**: The core Dart dependency injection library.
- **`complete_dependency_injector_flutter`**: Extensions for Flutter, including widgets for hierarchical injection and reactive ViewModels.

---

## Installation

Add the packages to your `pubspec.yaml`:

```yaml
dependencies:
  # Core DI for Dart
  complete_dependency_injector: ^2.0.3
  # Flutter integration (optional)
  complete_dependency_injector_flutter: ^2.0.3
```

Then run `dart pub get` or `flutter pub get`.

---

## Key Features

- **Hierarchical Injection**: Create nested scopes that inherit providers from their parents.
- **Scoped Providers**: Define dependencies at any level of the hierarchy, ensuring instances are isolated and managed within their respective scopes.
- **Asynchronous Service Creation**: First-class support for services that need asynchronous setup. Dependents automatically wait until a service reports that it is ready.
- **Async Initialization**: Use the `Ready` mixin for services that need to perform async work after construction (e.g., connecting to a database).
- **Flutter Integration**: Provides fine-grained state and update control like the BLoC pattern, but without any of the boilerplate.
- **ViewModel Pattern**: A robust pattern for bridging your business logic and UI, with built-in state handling for `ready`, `loading`, and `error` states.

---

## Core Concepts

### Providers, Factories, and Injectors

At the heart of `complete-dependency-injector` are **Providers**, **Factories**, and **Injectors**.

- **Providers** define the mapping of a token (usually a `Type`) to a specific implementation. They tell the injector *what* should be available in a given scope.
- **Factories** define *how* to create an instance of a type. They are registered globally and shared across all injectors. A factory specifies dependencies and construction logic.
- **Injectors** are containers that hold providers and manage the lifecycle of instances. They can be nested to create hierarchies.

**Important**: To get a service injected, you must define both a **Provider** (to register the type in a scope) and a **Factory** (to define how to build it). The only exceptions are `Provider.value` and `Provider.existing`, which do not require factories.

### Where Instances Live

An instance lives in the injector that **provides** it:

- Provide a service in the root injector and the whole app shares one instance.
- Provide it in a child injector (or an `InjectorScopeWidget`) and that child gets its own instance, which is disposed with it. Two children that both provide the type each get their own.

Factories only describe how to build a type, so the same factory works for an app-wide service and a per-scope one.

---

## User Guide (Angular-Inspired)

`complete-dependency-injector` follows a pattern where you define your construction logic once and provide it where it's needed.

### 1. Global Factory Registration

Factories only need to be registered once, typically at the start of your application.

```dart
// Register how to build services globally
rootInjector.registerFactories([
  InjectableFactory.withoutDependencies<AuthService>(() => AuthService()),
  
  InjectableFactory.withDependencies<UserRepository>(
    DependencyDataBuilder.list([AuthService, ApiClient]),
    (deps) => UserRepository(deps.get<AuthService>(), deps.get<ApiClient>()),
  ),
]);
```

### 2. Providing Services

Use **Providers** to make these services available in your root or child injectors.

```dart
// Root providers
final rootInjector = Injector([
  Provider(AuthService),
  Provider(ApiClient),
]);
```

### 3. Hierarchical Scoping

You can create a child scope and provide different services or even override parent providers.

```dart
// Each child that provides UserRepository gets its own instance.
// AuthService and ApiClient still come from the root.
final childInjector = Injector([
  Provider(UserRepository),
], parent: rootInjector);
```

### 4. Automatic Instance Creation

When you provide a type or token in a specific scope, the associated factory is triggered to create a new instance within that scope. This ensures that services are only created when and where they are needed.

---

## Async Services

Modern applications often have services that require asynchronous initialization. `complete-dependency-injector` makes this seamless with the `InjectableWithReadyMixin`.

### Defining an Async Service

```dart
class DatabaseService with InjectableWithReadyMixin {
  DatabaseService() {
    _init();
  }

  Future<void> _init() async {
    // Perform async setup like opening a database
    await Future.delayed(Duration(seconds: 1));
    setInjectableReadyResult(true); // Signal that the service is ready
  }
}
```

### Automatic Dependency Waiting

If another service depends on `DatabaseService`, it will automatically wait for the database to be fully initialized before it is constructed.

---

## Dependency Management with `DependencyDataBuilder`

The `DependencyDataBuilder` provides a fluent API for defining the requirements of your services. It supports positional and named dependencies, both required and optional.

### List-based Dependencies

For simple use cases, or when you prefer to manually resolve dependencies, use the concise `.list()` constructor. **Note**: Dependencies registered via `.list()` are treated as optional during the resolution phase.

```dart
// Resolves AuthService and ApiClient as optional positional dependencies
final dependencyData = DependencyDataBuilder.list([AuthService, ApiClient]);

// Manual resolution in factory
InjectableFactory.withDependencies<MyService>(
  dependencyData,
  (deps) => MyService(deps.get<AuthService>(), deps.get<ApiClient>()),
);
```

### Automatic Invocation with `invokeApply`

The primary reason to distinguish between named and positional dependencies is to support **automatic constructor invocation** using `invokeApply`. This eliminates the need to manually call `deps.get<T>()` for every parameter.

```dart
final dependencyData = DependencyDataBuilder()
  .namedRequired({
    'auth': AuthService,
    'client': ApiClient,
  })
  .done();

// Usage with invokeApply to automatically call the MyService constructor
InjectableFactory.withDependencies<MyService>(
  dependencyData,
  (deps) => deps.invokeApply(MyService.new),
);
```

---

## Flutter Integration

`complete-dependency-injector` provides a set of widgets to integrate dependency injection into your Flutter application's widget tree.

### `InjectorRootWidget`

Place the `InjectorRootWidget` at the top of your app to provide the root injector to the entire application.

```dart
void main() {
  final rootInjector = Injector([...]);
  runApp(InjectorRootWidget(
    injector: rootInjector,
    child: MyApp(),
  ));
}
```

### `InjectorScopeWidget`

Use `InjectorScopeWidget` to create a new injection scope for a specific part of your UI, like a screen or a complex component. This allows you to provide services that are only available within that specific subtree.

```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InjectorScopeWidget(
      providers: [
        // Provide a service specific to this screen
        Provider(ChatRepository),
      ],
      child: ChatContent(),
    );
  }
}
```

### The ViewModel Pattern

The recommended way to use `complete-dependency-injector` with Flutter is through the `ViewModel` pattern using `DependenciesBuilder`. 

Unlike services, **ViewModels are not injected**. Instead, a fresh instance of the ViewModel is passed directly to the `DependenciesBuilder`. The builder then uses the `Injector` to resolve the ViewModel's dependencies and automatically manages its state and stream observations.

This pattern provides **fine-grained state and update control like the BLoC pattern, but without any of the boilerplate**.

1. **Derive from `DependencyBuilderViewModelBase`**: Your ViewModel acts as a bridge between your business logic (services) and the UI.
2. **Define Dependencies**: Specify what services the ViewModel needs to resolve before it's "ready".
3. **Observe Streams**: Automatically observe business logic streams from your services. When any observed stream emits a new value, the ViewModel's update function is called, and the `DependenciesBuilder` re-builds the UI.
4. **Handle State**: Use the built-in `ready`, `loading`, and `error` flags to manage your UI state effortlessly.

> **Best Practice**: Services should not hold primitive state values. Instead, state should be managed using `BehaviorSubject` streams. The ViewModel then observes these streams and updates its own local properties to drive the UI.

```dart
class MyViewModel extends DependencyBuilderViewModelBase {
  late final AuthService authService;
  late final TaskService tasks; // Service exposed as 'tasks'

  // Local properties updated from service streams
  String userName = "";
  List<String> taskList = []; 

  MyViewModel() : super(dependencyDataList: DependencyDataBuilder.list([AuthService, TaskService]));

  @override
  void setPropertiesOnDependencyResolution(Dependencies dependencies) {
    authService = dependencies.get<AuthService>();
    tasks = dependencies.get<TaskService>();
  }

  // Observe multiple business logic streams from the services
  @override
  Iterable<Stream> getListOfStreamsToObserve() => [
    authService.userNameStream, 
    tasks.tasksStream,
  ];

  // Update ViewModel properties whenever any observed stream emits
  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    userName = snapshots[0] as String;
    taskList = snapshots[1] as List<String>;
  }
}
```

### `DependenciesBuilder` Widget

Use the `DependenciesBuilder` in your build function to access your ViewModel and its state.

```dart
DependenciesBuilder<MyViewModel>(
  cleanViewModelInstance: MyViewModel(),
  builder: (context, viewModel) {
    return dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
      context: context,
      viewModel: viewModel,
      build: (context, vm) => Scaffold(
        body: Text("Welcome, ${vm.userName}. Total tasks: ${vm.taskList.length}"),
        floatingActionButton: FloatingActionButton(
          onPressed: () => vm.tasks.addNewTask("Task #${vm.taskList.length + 1}"),
          child: Icon(Icons.add),
        ),
      ),
      loadingWidget: CircularProgressIndicator(),
      errorWidget: Text("Error loading dependencies"),
    );
  },
)
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
