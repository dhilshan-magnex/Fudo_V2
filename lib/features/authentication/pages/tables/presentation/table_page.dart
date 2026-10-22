import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fudo_v2/core/session/running_orders_store.dart';
import 'package:fudo_v2/core/session/session_provider.dart';
import 'package:fudo_v2/features/authentication/pages/tables/domain/table_models.dart';
import 'package:fudo_v2/features/authentication/pages/tables/state/table_layout_provider.dart';
import 'package:fudo_v2/core/theme/global_colors.dart';
import 'package:fudo_v2/features/orders/pages/dinein/dinein_page.dart';
import 'package:fudo_v2/shared/layout/layout.dart';
import 'package:fudo_v2/shared/widgets/buttons/back_button.dart';
import 'package:fudo_v2/shared/widgets/contact_form.dart';

part 'table_header.dart';
part 'table_grid.dart';
part 'table_details_dialog.dart';

class _TableOrderDetails {
  const _TableOrderDetails({
    required this.customerName,
    required this.waiterName,
    required this.pax,
  });

  final String customerName;
  final String waiterName;
  final int pax;
}

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
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TableLayoutProvider>().load());
  }

  void _reload() {
    context.read<TableLayoutProvider>().load();
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
  Widget build(BuildContext context) {
    final orderStore = context.watch<RunningOrdersStore>();
    final tableLayout = context.watch<TableLayoutProvider>();
    final occupiedTableNumbers = orderStore.orders
        .where((order) => !orderStore.isCompleted(order.billId))
        .map((order) => order.tableNumber?.trim().toLowerCase())
        .whereType<String>()
        .where((number) => number.isNotEmpty)
        .toSet();

    return Scaffold(
      backgroundColor: GlobalColors.homeBackground,
      body: HomeLayout(
        primaryContent: const _TableHeader(),
        sideContent: Builder(
          builder: (context) {
            if (tableLayout.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (tableLayout.error != null) {
              return _LoadError(onRetry: _reload);
            }

            final data = tableLayout.data;
            if (data == null) return _LoadError(onRetry: _reload);
            final activeSection =
                data.sections.any((section) => section.id == _selectedSectionId)
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
              occupiedTableNumbers: occupiedTableNumbers,
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
}
