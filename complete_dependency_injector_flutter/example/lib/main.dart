import 'dart:async';
import 'package:flutter/material.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:rxdart/rxdart.dart';

// --- Services ---

/// A simple service representing authentication state.
class AuthService {
  String get userName => "Developer";
}

/// A service that manages a list of tasks using a Stream.
/// Implements [InjectableWithDisposeInterface] to clean up resources.
class TaskService implements InjectableWithDisposeInterface {
  final _tasksSubject = BehaviorSubject<List<String>>.seeded(["Learn Complete-Dependency-Injector", "Write Great Code"]);
  Stream<List<String>> get tasksStream => _tasksSubject.stream;

  void addTask(String task) {
    final current = _tasksSubject.value;
    _tasksSubject.add([...current, task]);
  }

  @override
  Future<void> dispose() async {
    await _tasksSubject.close();
  }
}

// --- ViewModel ---

/// A ViewModel that uses [DependencyBuilderViewModelBase] to resolve its dependencies
/// and observe streams for automatic UI updates.
class TaskViewModel extends DependencyBuilderViewModelBase {
  late AuthService _auth;
  late TaskService _tasks;
  
  String userName = "";
  List<String> tasks = [];

  // Define what this ViewModel needs to resolve.
  TaskViewModel() : super(dependencyDataList: DependencyDataBuilder.list([AuthService, TaskService]));

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    _auth = deps<AuthService>();
    _tasks = deps<TaskService>();
    userName = _auth.userName;
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [_tasks.tasksStream];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    tasks = snapshots[0] as List<String>;
  }

  void addNewTask() {
    _tasks.addTask("New Task ${tasks.length + 1}");
  }
}

// --- UI ---

void main() {
  // 1. Initialize the Injector with Providers.
  final injector = Injector([
    Provider(AuthService),
    Provider(TaskService),
  ]);

  // 2. Register Factories for the services.
  injector.registerFactories([
    InjectableFactory.withoutDependencies<AuthService>(() => AuthService()),
    InjectableFactory.withoutDependencies<TaskService>(() => TaskService()),
  ]);

  // 3. Wrap the app in InjectorRootWidget to provide the injector.
  runApp(InjectorRootWidget(
    injector: injector,
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskScreen(),
    ),
  ));
}

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete-Dependency-Injector Example"),
        backgroundColor: Colors.blueGrey,
      ),
      // 4. Use DependenciesBuilder to resolve the ViewModel and build UI.
      body: DependenciesBuilder<TaskViewModel>(
        cleanViewModelInstance: TaskViewModel(),
        builder: (context, vm) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Welcome, ${vm.userName}!",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Your Tasks:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.tasks.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(vm.tasks[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // We can use another DependenciesBuilder for the FAB to keep it responsive.
      floatingActionButton: DependenciesBuilder<TaskViewModel>(
        cleanViewModelInstance: TaskViewModel(),
        builder: (context, vm) {
          return FloatingActionButton(
            onPressed: vm.ready ? () => vm.addNewTask() : null,
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
