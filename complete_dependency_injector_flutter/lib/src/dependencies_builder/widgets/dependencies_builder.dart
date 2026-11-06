import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import '../../lib_internal_main.dart';

/// Resolves a ViewModel's dependencies from the nearest injector, then
/// rebuilds whenever one of the ViewModel's observed streams emits.
///
/// The first [cleanViewModelInstance] is kept for this widget's lifetime, so a
/// ViewModel created inside a parent's `build` keeps its state when the parent
/// rebuilds. Give the widget a new `key` to start over with a new ViewModel.
class DependenciesBuilder<T extends DependencyBuilderViewModelBase> extends StatefulWidget {
  final T viewModel;
  final DependenciesBuilderBuildFn<T> builder;

  const DependenciesBuilder({
    super.key,
    required T cleanViewModelInstance,
    required this.builder,
  }) : viewModel = cleanViewModelInstance;

  @override
  State<DependenciesBuilder<T>> createState() => _DependenciesBuilderState<T>();
}

class _DependenciesBuilderState<T extends DependencyBuilderViewModelBase> extends State<DependenciesBuilder<T>> {
  late final T _viewModel = widget.viewModel;
  Future<Dependencies>? _dependenciesFuture;

  // Created once, after the dependencies resolve. Building a new stream on each
  // rebuild would make StreamBuilder re-listen: the ViewModel would drop back to
  // loading until the next emission, and a single-subscription stream would throw.
  bool _streamsRead = false;
  Stream<List<dynamic>>? _combinedStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final injectorContainer = InjectorContainerWidget.of(context);
    assert(injectorContainer != null, "Attempting to use DependenciesBuilder with no InjectorScopeWidget in tree");

    _dependenciesFuture ??= injectorContainer!.injector.resolveDependencies(_viewModel.dependencyDataList);
  }

  Stream<List<dynamic>>? _streamFor(T viewModel) {
    if (!_streamsRead) {
      _streamsRead = true;
      final streams = viewModel.getListOfStreamsToObserve();
      if (streams.isNotEmpty) _combinedStream = Rx.combineLatestList(streams);
    }
    return _combinedStream;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    return FutureBuilder<Dependencies>(
      future: _dependenciesFuture,
      builder: (context, depSnapshot) {
        if (depSnapshot.connectionState != ConnectionState.done) {
          viewModel.updateFromAsyncDependenciesDataChange(false);
          return widget.builder(context, viewModel);
        }

        if (depSnapshot.hasError) {
          viewModel.updateFromAsyncDependenciesDataChange(true);
          return widget.builder(context, viewModel);
        }

        final Dependencies dependencies = depSnapshot.data!;
        viewModel.updateFromAsyncDependenciesDataChange(false, dependencies);

        final stream = _streamFor(viewModel);
        if (stream == null) {
          viewModel.updateFromAsyncDependenciesDataChange(false, dependencies, []);
          return widget.builder(context, viewModel);
        }

        return StreamBuilder<List<dynamic>>(
          stream: stream,
          builder: (context, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return widget.builder(context, viewModel);
            }
            if (streamSnapshot.hasError || !streamSnapshot.hasData) {
              viewModel.updateFromAsyncDependenciesDataChange(true, dependencies);
              return widget.builder(context, viewModel);
            }
            viewModel.updateFromAsyncDependenciesDataChange(false, dependencies, streamSnapshot.data!);
            return widget.builder(context, viewModel);
          },
        );
      },
    );
  }
}
