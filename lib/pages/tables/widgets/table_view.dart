part of '../table_page.dart';

class _TablePageState extends _TableController {
  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final tableLayout = context.watch<TableLayoutProvider>();
    final occupiedTableNumbers = orderProvider.openTableOrders
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
