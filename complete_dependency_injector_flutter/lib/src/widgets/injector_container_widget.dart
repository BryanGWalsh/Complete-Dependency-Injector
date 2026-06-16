import 'package:flutter/widgets.dart';
import 'package:complete_dependency_injector/complete_dependency_injector.dart';

/// An internal [InheritedWidget] that holds the [Injector] instance.
///
/// Use [InjectorContainerWidget.of] to retrieve the [Injector] from the context.
class InjectorContainerWidget extends InheritedWidget {
  /// The [Injector] instance managed by this container.
  final Injector injector;

  /// Internal constructor.
  const InjectorContainerWidget({required super.child, super.key, required this.injector});

  /// Retrieves the [InjectorContainerWidget] from the given [context].
  static InjectorContainerWidget? of(BuildContext context) => context.getInheritedWidgetOfExactType<InjectorContainerWidget>();

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
