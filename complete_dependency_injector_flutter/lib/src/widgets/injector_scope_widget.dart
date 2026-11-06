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
  // Kept across rebuilds so cached instances survive. Replaced only when the
  // parent injector or the providers actually change.
  Injector? _injector;
  Injector? _parent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A real dependency, so moving this scope under another parent (for
    // example with a GlobalKey) calls this again.
    final parent = context.dependOnInheritedWidgetOfExactType<InjectorContainerWidget>()?.injector;
    if (_injector == null || !identical(parent, _parent)) _recreate(parent);
  }

  @override
  void didUpdateWidget(InjectorScopeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProviders(oldWidget._providers, widget._providers)) _recreate(_parent);
  }

  void _recreate(Injector? parent) {
    // The old injector is disposed by InjectorProviderWidget when it sees the
    // new one.
    _parent = parent;
    _injector = Injector(widget._providers, parent: parent);
  }

  /// Providers are usually rebuilt in every build, so compare what they
  /// provide rather than the Provider objects themselves.
  static bool _sameProviders(List<Provider> a, List<Provider> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (identical(a[i], b[i])) continue;
      final sa = a[i].strategies.toList();
      final sb = b[i].strategies.toList();
      if (sa.length != sb.length) return false;
      for (var j = 0; j < sa.length; j++) {
        if (sa[j].provides != sb[j].provides || sa[j].useExisting != sb[j].useExisting || sa[j].useValue != sb[j].useValue) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => InjectorProviderWidget(injector: _injector!, child: widget._child);
}
