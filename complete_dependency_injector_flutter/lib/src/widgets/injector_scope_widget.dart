import 'package:flutter/widgets.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'injector_container_widget.dart';
import 'injector_provider_widget.dart';

/// A widget that creates a new [Injector] scope.
///
/// This widget creates a child [Injector] that inherits providers from the
/// nearest [Injector] above it in the widget tree (if any). It then provides
/// this new injector to its descendants.
class InjectorScopeWidget extends StatefulWidget {
  final List<Provider> _providers;
  final Widget _child;

  /// Creates an [InjectorScopeWidget].
  ///
  /// * [child]: The widget subtree that will have access to the new [Injector].
  /// * [providers]: A list of [Provider]s to register in the new [Injector].
  /// * [injector]: Optional. Currently unused by the constructor, but kept for
  ///   consistency with other widgets.
  const InjectorScopeWidget({required Widget child, super.key, required List<Provider> providers, Injector? injector})
      : _providers = providers,
        _child = child;

  @override
  State<InjectorScopeWidget> createState() => _InjectorScopeWidgetState();
}

class _InjectorScopeWidgetState extends State<InjectorScopeWidget> {
  // Created once, on the first build. A parent keeps track of its child
  // injectors, so creating one per build would leave the extras attached to
  // the parent until it is disposed.
  Injector? _injector;

  @override
  Widget build(BuildContext context) {
    final injector = _injector ??= Injector(widget._providers, parent: InjectorContainerWidget.of(context)?.injector);
    return InjectorProviderWidget(injector: injector, child: widget._child);
  }
}
