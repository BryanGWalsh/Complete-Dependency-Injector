import 'package:flutter/widgets.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

import 'injector_provider_widget.dart';


/// A widget that provides an [Injector] to the entire application.
///
/// This is typically placed at the very top of the widget tree, above [MaterialApp]
/// or [CupertinoApp], to make the root [Injector] available everywhere.
class InjectorRootWidget extends StatelessWidget {
  final Widget _child;
  final Injector _injector;

  /// Creates an [InjectorRootWidget].
  ///
  /// * [injector]: The root [Injector] instance to provide.
  /// * [child]: The widget subtree (usually the whole app).
  const InjectorRootWidget({required Injector injector, super.key, required Widget child})
      : _injector = injector,
        _child = child;

  @override
  Widget build(BuildContext context) => InjectorProviderWidget(injector: _injector, child: _child);
}


