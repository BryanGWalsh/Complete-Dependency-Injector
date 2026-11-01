import 'package:flutter/widgets.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'injector_container_widget.dart';

/// Places an [Injector] in the widget tree and disposes it when this widget
/// is removed. Used by [InjectorRootWidget] and [InjectorScopeWidget]; you
/// normally don't use it directly.
class InjectorProviderWidget extends StatefulWidget {
  final Injector _injector;
  final Widget _child;

  const InjectorProviderWidget({super.key, required Injector injector, required Widget child})
      : _injector = injector,
        _child = child;

  @override
  State<InjectorProviderWidget> createState() => _InjectorProviderWidgetState();
}

class _InjectorProviderWidgetState extends State<InjectorProviderWidget> {
  // The injector from the first build is kept for this widget's lifetime, so
  // its cached instances survive rebuilds.
  late final Injector _injector = widget._injector;

  @override
  void dispose() {
    _injector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InjectorContainerWidget(injector: _injector, child: widget._child);
}
