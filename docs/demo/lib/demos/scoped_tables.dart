// Scoped services: two tables on one screen, each with its own TableManager,
// both reading from one shared ProductRepository.
import 'package:complete_dependency_injector/complete_dependency_injector.dart';
import 'package:complete_dependency_injector_flutter/complete_dependency_injector_flutter.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class Product {
  const Product(this.name, this.price);
  final String name;
  final double price;
}

// #region repository
/// Shared data source. Root scope (the default): one for the whole app.
class ProductRepository {
  static final Factory = InjectableFactory.withoutDependencies<ProductRepository>(
    () => ProductRepository(),
  );
  static final DefaultProvider = Provider(ProductRepository);

  List<Product> all() => const [
        Product('Keyboard', 49),
        Product('Monitor', 199),
        Product('Mouse', 19),
        Product('Webcam', 79),
      ];
}
// #endregion repository

// #region manager
class TableState {
  const TableState({required this.rows, required this.sortColumn, required this.ascending, this.selected});
  final List<Product> rows;
  final int sortColumn;
  final bool ascending;
  final String? selected;
}

/// Sorting and selection for one table.
class TableManager implements InjectableWithDisposeInterface {
  TableManager(ProductRepository repository)
      : _state = BehaviorSubject.seeded(
          TableState(rows: repository.all(), sortColumn: 0, ascending: true),
        );

  static final Factory = InjectableFactory.withDependencies<TableManager>(
    DependencyDataBuilder.list([ProductRepository]),
    (deps) => TableManager(deps.get<ProductRepository>()),
    // One TableManager per injector that provides it.
    scope: InjectableScope.instance,
  );
  static final DefaultProvider = Provider(TableManager);

  static int _created = 0;
  final int id = ++_created;

  final BehaviorSubject<TableState> _state;
  Stream<TableState> get state => _state.stream;

  void sortBy(int column, bool ascending) {
    final rows = [..._state.value.rows]..sort((a, b) {
        final result = column == 0 ? a.name.compareTo(b.name) : a.price.compareTo(b.price);
        return ascending ? result : -result;
      });
    _state.add(TableState(rows: rows, sortColumn: column, ascending: ascending, selected: _state.value.selected));
  }

  void select(String name) {
    final s = _state.value;
    _state.add(TableState(rows: s.rows, sortColumn: s.sortColumn, ascending: s.ascending, selected: name));
  }

  @override
  Future<void> dispose() => _state.close();
}
// #endregion manager

// #region view-model
class TableViewModel extends DependencyBuilderViewModelBase {
  TableViewModel()
      : super(dependencyDataList: DependencyDataBuilder.list([TableManager]));

  late TableManager manager;
  late TableState table;

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    manager = deps<TableManager>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() => [manager.state];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    table = snapshots[0] as TableState;
  }
}
// #endregion view-model

// #region widgets
/// Wrapping each table in its own InjectorScopeWidget is what gives it
/// its own TableManager.
class ScopedTablesDemo extends StatelessWidget {
  const ScopedTablesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final title in ['Table A', 'Table B'])
            InjectorScopeWidget(
              providers: [TableManager.DefaultProvider],
              child: ProductTable(title: title),
            ),
        ],
      ),
    );
  }
}

class ProductTable extends StatelessWidget {
  const ProductTable({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DependenciesBuilder<TableViewModel>(
      cleanViewModelInstance: TableViewModel(),
      builder: (context, vm) => dependencyBuilderViewModelSimpleStateHandlingBuildUtilityFn(
        context: context,
        viewModel: vm,
        loadingWidget: const SizedBox(width: 280, height: 200, child: Center(child: CircularProgressIndicator())),
        build: (context, vm) => SizedBox(
          width: 280,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title · TableManager #${vm.manager.id}', style: Theme.of(context).textTheme.titleMedium),
                  Text('Selected: ${vm.table.selected ?? 'none'}', key: Key('$title-selected')),
                  DataTable(
                    key: Key('$title-table'),
                    sortColumnIndex: vm.table.sortColumn,
                    sortAscending: vm.table.ascending,
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(label: const Text('Product'), onSort: vm.manager.sortBy),
                      DataColumn(label: const Text('Price'), numeric: true, onSort: vm.manager.sortBy),
                    ],
                    rows: [
                      for (final p in vm.table.rows)
                        DataRow(
                          selected: p.name == vm.table.selected,
                          onSelectChanged: (_) => vm.manager.select(p.name),
                          cells: [DataCell(Text(p.name)), DataCell(Text('\$${p.price.toStringAsFixed(0)}'))],
                        ),
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
