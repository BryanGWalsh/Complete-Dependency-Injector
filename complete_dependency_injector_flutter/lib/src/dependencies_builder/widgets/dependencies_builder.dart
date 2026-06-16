import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import '../../lib_internal_main.dart';

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
  Future<Dependencies>? _dependenciesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final injectorContainer = InjectorContainerWidget.of(context);
    assert(injectorContainer != null, "Attempting to use DependenciesBuilder with no InjectorScopeWidget in tree");
    
    _dependenciesFuture ??= injectorContainer!.injector.resolveDependencies(widget.viewModel.dependencyDataList);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dependencies>(
      future: _dependenciesFuture,
      builder: (context, depSnapshot) {
        if (depSnapshot.connectionState != ConnectionState.done) {
          widget.viewModel.updateFromAsyncDependenciesDataChange(false);
          return widget.builder(context, widget.viewModel);
        }

        if (depSnapshot.hasError) {
          widget.viewModel.updateFromAsyncDependenciesDataChange(true);
          return widget.builder(context, widget.viewModel);
        }

        final Dependencies dependencies = depSnapshot.data!;
        widget.viewModel.updateFromAsyncDependenciesDataChange(false, dependencies);
        
        final streams = widget.viewModel.getListOfStreamsToObserve();
        if (streams.isEmpty) {
           widget.viewModel.updateFromAsyncDependenciesDataChange(false, dependencies, []);
           return widget.builder(context, widget.viewModel);
        }

        return StreamBuilder<List<dynamic>>(
          stream: Rx.combineLatestList(streams),
          builder: (context, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return widget.builder(context, widget.viewModel);
            }
            if (streamSnapshot.hasError || !streamSnapshot.hasData) {
              widget.viewModel.updateFromAsyncDependenciesDataChange(true, dependencies);
              return widget.builder(context, widget.viewModel);
            }
            widget.viewModel.updateFromAsyncDependenciesDataChange(false, dependencies, streamSnapshot.data!);
            return widget.builder(context, widget.viewModel);
          },
        );
      },
    );
  }
}
