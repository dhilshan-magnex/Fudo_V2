import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_manager.dart';
import '../layout/layout.dart';
import '../session/session_provider.dart';
import '../utils/global_colors.dart';
import '../widgets/buttons/back_button.dart';

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

    final sectionModels = sections
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _TableDetailsDialog(
        table: table,
        // The session's _clientName is exposed through clientName.
        waiterName: session.userName?.trim().isNotEmpty == true
            ? session.userName!.trim()
            : session.clientName?.trim() ?? '',
      ),
    );

    if (confirmed == true && mounted) {
      widget.onTableSelected?.call(table);
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
              final activeSection = _selectedSectionId ??
                  (data.sections.isEmpty ? null : data.sections.first.id);
              final visibleTables = data.tables
                  .where((table) =>
                      activeSection == null || table.sectionId == activeSection)
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'FUDO V2',
                      style: TextStyle(
                        color: GlobalColors.homeHeaderForeground,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? 96 : 112,
                    height: 56,
                    child: const FudoBackButton(),
                  ),
                ],
              ),
              SizedBox(height: compact ? 12 : 24),
              Text(
                'Select a table',
                style: TextStyle(
                  color: GlobalColors.homeHeaderForeground,
                  fontSize: compact ? 26 : 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a table to start or continue an order',
                style: TextStyle(
                  color: GlobalColors.homeHeaderLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      );
}

class _TableContent extends StatelessWidget {
  const _TableContent({
    required this.sections,
    required this.tables,
    required this.selectedSectionId,
    required this.onSectionChanged,
    required this.onTableSelected,
    required this.onRefresh,
  });

  final List<TableSection> sections;
  final List<TableLayoutTable> tables;
  final String? selectedSectionId;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<TableLayoutTable> onTableSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppLayoutType.fromContext(context).isMobile;
    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = tables.isEmpty
            ? const _EmptyTables()
            : _TableGrid(
                tables: tables,
                isMobile: isMobile,
                onTableSelected: onTableSelected,
                shrinkWrap: !constraints.maxHeight.isFinite,
              );
        final header = <Widget>[
          Row(
          children: [
            const Expanded(
              child: Text(
                'Tables',
                style: TextStyle(
                  color: GlobalColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh tables',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sections.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final section = sections[index];
                final selected = section.id == selectedSectionId;
                return ChoiceChip(
                  label: Text(section.name),
                  selected: selected,
                  onSelected: (_) => onSectionChanged(section.id),
                  selectedColor: GlobalColors.homeActionBackground,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : GlobalColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  side: const BorderSide(color: GlobalColors.billingCardBorder),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        ];

        if (!constraints.maxHeight.isFinite) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...header, grid],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...header, Expanded(child: grid)],
        );
      },
    );
  }
}

class _TableGrid extends StatelessWidget {
  const _TableGrid({
    required this.tables,
    required this.isMobile,
    required this.onTableSelected,
    this.shrinkWrap = false,
  });

  final List<TableLayoutTable> tables;
  final bool isMobile;
  final ValueChanged<TableLayoutTable> onTableSelected;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 5
              : constraints.maxWidth >= 560
                  ? 4
                  : isMobile
                      ? 2
                      : 3;
          return GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: tables.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) => _TableTile(
              table: tables[index],
              onTap: () => onTableSelected(tables[index]),
            ),
          );
        },
      );
}

class _TableDetailsDialog extends StatefulWidget {
  const _TableDetailsDialog({required this.table, required this.waiterName});

  final TableLayoutTable table;
  final String waiterName;

  @override
  State<_TableDetailsDialog> createState() => _TableDetailsDialogState();
}

class _TableDetailsDialogState extends State<_TableDetailsDialog> {
  late final TextEditingController _customerController;
  late final TextEditingController _waiterController;
  final _paxController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _waiterController = TextEditingController(text: widget.waiterName);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _waiterController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppLayoutType.fromContext(context).isMobile;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: (screenHeight - 48).clamp(240.0, screenHeight * 0.9),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            color: GlobalColors.homeHeaderBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.table_restaurant_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Table ${widget.table.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Enter order details to continue',
                              style: TextStyle(
                                color: GlobalColors.homeHeaderLabel,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _DialogField(
                    controller: _customerController,
                    label: 'Customer',
                    icon: Icons.person_outline,
                    capitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: _waiterController,
                    label: 'Waiter',
                    icon: Icons.badge_outlined,
                    capitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a waiter name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: _paxController,
                    label: 'Pax',
                    icon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final pax = int.tryParse(value?.trim() ?? '');
                      return pax == null || pax < 1
                          ? 'Enter at least 1 guest'
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogAction(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          outlined: true,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogAction(
                          label: 'Confirm',
                          icon: Icons.check_rounded,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context).pop(true);
                            }
                          },
                        ),
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

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        textCapitalization: capitalization,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: GlobalColors.primaryText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromARGB(255, 87, 88, 88)),
          prefixIcon: Icon(icon, color: GlobalColors.homeActionBackground),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: GlobalColors.homeStatusBackground,
              width: 2,
            ),
          ),
        ),
      );
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: outlined
              ? Colors.white
              : GlobalColors.homeHeaderBackground,
          backgroundColor: outlined ? Colors.transparent : Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined
                ? const BorderSide(color: GlobalColors.homeHeaderLabel)
                : BorderSide.none,
          ),
        ),
      );
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table, this.onTap});

  final TableLayoutTable table;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRound = table.shape.toLowerCase().contains('round') ||
        table.shape.toLowerCase().contains('circle');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isRound ? 80 : 18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isRound ? 80 : 18),
            border: Border.all(color: GlobalColors.billingCardBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_restaurant_outlined,
                    color: GlobalColors.homeActionBackground, size: 30),
                const SizedBox(height: 8),
                Text(
                  table.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GlobalColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTables extends StatelessWidget {
  const _EmptyTables();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.table_restaurant_outlined,
                size: 48, color: GlobalColors.secondaryText),
            SizedBox(height: 12),
            Text('No active tables found',
                style: TextStyle(
                    color: GlobalColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Sync table layouts, then refresh this page.',
                style: TextStyle(color: GlobalColors.secondaryText)),
          ],
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Could not load tables. Retry'),
        ),
      );
}

class _TablePageData {
  const _TablePageData(this.sections, this.tables);
  final List<TableSection> sections;
  final List<TableLayoutTable> tables;
}

class TableSection {
  const TableSection(this.id, this.name, this.order);
  factory TableSection.fromRow(Map<String, dynamic> row) {
    final id = row['Section_ID']?.toString().trim() ?? '';
    final name = row['Section_Name']?.toString().trim() ?? '';
    return TableSection(
      id,
      name.isNotEmpty ? name : id,
      num.tryParse(row['Section_Order']?.toString() ?? '')?.toInt() ?? 0,
    );
  }
  final String id;
  final String name;
  final int order;
}

class TableLayoutTable {
  const TableLayoutTable({
    required this.number,
    required this.sectionId,
    required this.shape,
    required this.isActive,
  });

  factory TableLayoutTable.fromRow(Map<String, dynamic> row) {
    final active = row['Active']?.toString().trim().toLowerCase();
    return TableLayoutTable(
      number: row['Table_No']?.toString().trim() ?? '',
      sectionId: row['Section_ID']?.toString().trim() ?? '',
      shape: row['Table_Shape']?.toString().trim() ?? '',
      isActive: active == null ||
          active.isEmpty ||
          active == '1' ||
          active == 'true' ||
          active == 'yes',
    );
  }

  final String number;
  final String sectionId;
  final String shape;
  final bool isActive;
}
