// Interfaces: widgets depend on an abstract PriceFormatter. The root provides
// one implementation and a scope swaps in another, without the widgets knowing.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';

// #region interface
/// What the UI depends on.
abstract class PriceFormatter {
  // The app-wide default: ask for PriceFormatter, get a UsdFormatter.
  static final DefaultProvider = Provider.factory(PriceFormatter, fromDerived: UsdFormatter);
  // The same interface, backed by a different implementation.
  static final EuroProvider = Provider.factory(PriceFormatter, fromDerived: EurFormatter);

  String get label;
  String format(double amount);
}
// #endregion interface

// #region implementations
class UsdFormatter implements PriceFormatter {
  static final Factory = InjectableFactory.withoutDependencies<UsdFormatter>(() => UsdFormatter());

  @override
  String get label => 'UsdFormatter';

  @override
  String format(double amount) => '\$${amount.toStringAsFixed(2)}';
}

class EurFormatter implements PriceFormatter {
  static final Factory = InjectableFactory.withoutDependencies<EurFormatter>(() => EurFormatter());

  @override
  String get label => 'EurFormatter';

  @override
  String format(double amount) => '${(amount * 0.92).toStringAsFixed(2).replaceAll('.', ',')} €';
}
// #endregion implementations

// #region view-model
/// Asks for the interface. It never names an implementation.
class PriceListViewModel extends DependencyBuilderViewModelBase {
  PriceListViewModel()
      : super(dependencyDataList: DependencyDataBuilder.list([PriceFormatter]));

  late PriceFormatter formatter;

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    formatter = deps<PriceFormatter>();
  }

  // Nothing here changes over time, so there are no streams to observe.
  @override
  Iterable<Stream> getListOfStreamsToObserve() => const [];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {}
}
// #endregion view-model

// #region widgets
class InterfacesDemo extends StatelessWidget {
  const InterfacesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          // Uses whatever the root provides.
          const PriceList(title: 'Root default'),
          // This scope provides PriceFormatter again, backed by EurFormatter.
          InjectorScopeWidget(
            providers: [PriceFormatter.EuroProvider],
            child: const PriceList(title: 'Euro scope'),
          ),
        ],
      ),
    );
  }
}

class PriceList extends StatelessWidget {
  const PriceList({super.key, required this.title});
  final String title;

  static const prices = {'Keyboard': 49.0, 'Monitor': 199.0, 'Mouse': 19.5};

  @override
  Widget build(BuildContext context) {
    return DependenciesBuilder<PriceListViewModel>(
      cleanViewModelInstance: PriceListViewModel(),
      builder: (context, vm) => dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
        context: context,
        viewModel: vm,
        loadingWidget: const SizedBox(width: 260, height: 160, child: Center(child: CircularProgressIndicator())),
        build: (context, vm) => SizedBox(
          width: 260,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text('PriceFormatter is ${vm.formatter.label}', key: Key('$title-impl')),
                  const Divider(),
                  for (final entry in prices.entries)
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(vm.formatter.format(entry.value)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion widgets
