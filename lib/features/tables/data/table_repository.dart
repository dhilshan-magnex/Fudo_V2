import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:fudo_v2/features/tables/domain/table_models.dart';

/// Local table-layout data access. Data Sync keeps these tables current for
/// API clients, so this repository remains usable when the POS is offline.
class TableRepository {
  const TableRepository();

  Future<TableLayoutData> loadTableLayout() async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final sections = await database.query('Section_Master');
    final tables = await database.query('Table_Layout');

    final sectionModels =
        sections
            .map(TableSection.fromRow)
            .where((section) => section.id.isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final tableModels = tables
        .map(TableLayoutTable.fromRow)
        .where((table) => table.number.isNotEmpty && table.isActive)
        .toList();

    if (sectionModels.isEmpty && tableModels.isNotEmpty) {
      final ids = tableModels.map((table) => table.sectionId).toSet();
      sectionModels.addAll(ids.map((id) => TableSection(id, id, 0)));
    }

    return TableLayoutData(sectionModels, tableModels);
  }
}
