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
/// Shared data source. Provided at the root, so the whole app shares one.
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
/// Sorting and selection for one table. Provided by each table's scope, so
/// each table gets its own. Each piece of state is its own stream.
class TableManager implements InjectableWithDisposeInterface {
  TableManager(ProductRepository repository) : _rows = BehaviorSubject.seeded(repository.all());

  static final Factory = InjectableFactory.withDependencies<TableManager>(
    DependencyDataBuilder.list([ProductRepository]),
    (deps) => TableManager(deps.get<ProductRepository>()),
  );
  static final DefaultProvider = Provider(TableManager);

  static int _created = 0;
  final int id = ++_created;

  final BehaviorSubject<List<Product>> _rows;
  final _sortColumn = BehaviorSubject<int>.seeded(0);
  final _ascending = BehaviorSubject<bool>.seeded(true);
  final _selected = BehaviorSubject<String?>.seeded(null);

  Stream<List<Product>> get rows => _rows.stream;
  Stream<int> get sortColumn => _sortColumn.stream;
  Stream<bool> get ascending => _ascending.stream;
  Stream<String?> get selected => _selected.stream;

  void sortBy(int column, bool ascending) {
    final sorted = [..._rows.value]..sort((a, b) {
        final result = column == 0 ? a.name.compareTo(b.name) : a.price.compareTo(b.price);
        return ascending ? result : -result;
      });
    _sortColumn.add(column);
    _ascending.add(ascending);
    _rows.add(sorted);
  }

  void select(String name) => _selected.add(name);

  @override
  Future<void> dispose() async {
    await Future.wait([_rows.close(), _sortColumn.close(), _ascending.close(), _selected.close()]);
  }
}
// #endregion manager

// #region view-model
class TableViewModel extends DependencyBuilderViewModelBase {
  TableViewModel()
      : super(dependencyDataList: DependencyDataBuilder.list([TableManager]));

  late TableManager manager;

  // Local copies of the service's streams, used by the UI.
  List<Product> rows = [];
  int sortColumn = 0;
  bool ascending = true;
  String? selected;

  @override
  void setPropertiesOnDependencyResolution(Dependencies deps) {
    manager = deps<TableManager>();
  }

  @override
  Iterable<Stream> getListOfStreamsToObserve() =>
      [manager.rows, manager.sortColumn, manager.ascending, manager.selected];

  @override
  void updateViewModelPropertiesOnStreamEmission(List snapshots) {
    rows = snapshots[0] as List<Product>;
    sortColumn = snapshots[1] as int;
    ascending = snapshots[2] as bool;
    selected = snapshots[3] as String?;
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
                  Text('Selected: ${vm.selected ?? 'none'}', key: Key('$title-selected')),
                  DataTable(
                    key: Key('$title-table'),
                    sortColumnIndex: vm.sortColumn,
                    sortAscending: vm.ascending,
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(label: const Text('Product'), onSort: vm.manager.sortBy),
                      DataColumn(label: const Text('Price'), numeric: true, onSort: vm.manager.sortBy),
                    ],
                    rows: [
                      for (final p in vm.rows)
                        DataRow(
                          selected: p.name == vm.selected,
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
