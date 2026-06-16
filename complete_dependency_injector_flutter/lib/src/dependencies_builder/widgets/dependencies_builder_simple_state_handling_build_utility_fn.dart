import 'package:flutter/widgets.dart';
import "../../lib_internal_main.dart";

Widget dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn<T extends DependencyBuilderViewModelBase>(
    {required BuildContext context,
      required T viewModel,
      required DependenciesBuilderBuildFn<T> build,
      Widget? loadingWidget,
      DependenciesBuilderBuildFn<T>? loadingWidgetBuilder,
      Widget? errorWidget,
      DependenciesBuilderBuildFn<T>? errorWidgetBuilder}){
  if(viewModel.ready) return build(context, viewModel);
  if(viewModel.error){
    if(errorWidget != null) return errorWidget;
    if(errorWidgetBuilder != null) return errorWidgetBuilder(context, viewModel);
    return Container();
  }
  if(viewModel.loading){
    if(loadingWidget != null) return loadingWidget;
    if(loadingWidgetBuilder != null) return loadingWidgetBuilder(context, viewModel);
    return Container();
  }
  return Container();


}