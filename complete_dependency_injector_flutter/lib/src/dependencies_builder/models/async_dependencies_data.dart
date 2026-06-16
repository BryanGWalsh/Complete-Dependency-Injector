import 'package:complete_dependency_injector/complete_dependency_injector.dart';

class AsyncDependenciesData {
  final bool hasError;
  final Dependencies? dependencies;
  final List<dynamic>? streamSnapshots;

  AsyncDependenciesData({
    required this.hasError,
    this.dependencies,
    this.streamSnapshots,
  });
}

