import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/db_manager.dart';
import '../../layout/layout.dart';
import '../../session/session_provider.dart';
import '../../utils/global_colors.dart';
import '../../widgets/buttons/back_button.dart';
import '../dinein/dinein_page.dart';

part 'table_header.dart';
part 'table_grid.dart';
part 'table_details_dialog.dart';
part 'table_models.dart';

/// Displays the restaurant floor plan stored in `Table_Layout`.
///
/// The layout data is deliberately read from the local database: it is kept up
/// to date by Data Sync and therefore still works while the POS is offline.
class TablePage extends StatefulWidget {
  const TablePage({super.key, this.onTableSelected});

  final ValueChanged<TableLayoutTable>? onTableSelected;

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  late Future<_TablePageData> _dataFuture;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_TablePageData> _loadData() async {
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

    // Some installations have table layouts but no section master rows. Keep
    // those tables visible instead of presenting an empty screen.
    if (sectionModels.isEmpty && tableModels.isNotEmpty) {
      final ids = tableModels.map((table) => table.sectionId).toSet();
      sectionModels.addAll(ids.map((id) => TableSection(id, id, 0)));
    }

    return _TablePageData(sectionModels, tableModels);
  }

  void _reload() {
    setState(() => _dataFuture = _loadData());
  }

  Future<void> _selectTable(TableLayoutTable table) async {
    final session = context.read<SessionProvider>();
    final details = await showDialog<_TableOrderDetails>(
      context: context,
      builder: (_) => _TableDetailsDialog(
        table: table,
        // The session's _clientName is exposed through clientName.
        waiterName: session.userName?.trim().isNotEmpty == true
            ? session.userName!.trim()
            : session.clientName?.trim() ?? '',
      ),
    );

    if (details != null && mounted) {
      widget.onTableSelected?.call(table);
      final orderConfirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DineInPage(
            tableNumber: table.number,
            customerName: details.customerName,
            waiterName: details.waiterName,
            pax: details.pax,
          ),
        ),
      );
      if (orderConfirmed == true && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GlobalColors.homeBackground,
    body: HomeLayout(
      primaryContent: const _TableHeader(),
      sideContent: FutureBuilder<_TablePageData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(onRetry: _reload);
          }

          final data = snapshot.data!;
          final activeSection = data.sections.any(
                    (section) => section.id == _selectedSectionId,
                  )
              ? _selectedSectionId
              : (data.sections.isEmpty ? null : data.sections.first.id);
          final visibleTables = data.tables
              .where(
                (table) =>
                    activeSection == null ||
                    table.sectionId.isEmpty ||
                    table.sectionId == activeSection,
              )
              .toList();
          return _TableContent(
            sections: data.sections,
            tables: visibleTables,
            selectedSectionId: activeSection,
            onSectionChanged: (id) => setState(() => _selectedSectionId = id),
            onTableSelected: _selectTable,
            onRefresh: _reload,
          );
        },
      ),
    ),
  );
}
