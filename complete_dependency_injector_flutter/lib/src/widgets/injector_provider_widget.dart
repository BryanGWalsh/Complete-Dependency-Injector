import 'package:flutter/widgets.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'injector_container_widget.dart';

// do not use
class InjectorProviderWidget extends StatefulWidget{
  final Injector _injector;
  final Widget _child;
  const InjectorProviderWidget({super.key, required injector, required child}): _injector = injector, _child = child;
  @override
  State<StatefulWidget> createState()  => _InjectorProviderWidgetState(injector: _injector, child: _child);
}
class _InjectorProviderWidgetState extends State<InjectorProviderWidget>{
  final Injector _injector;
  final Widget _child;
  _InjectorProviderWidgetState({required Injector injector, required Widget child}): _injector = injector, _child = child;
  @override
  void dispose() {
    _injector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InjectorContainerWidget(injector: _injector, child: _child);
}