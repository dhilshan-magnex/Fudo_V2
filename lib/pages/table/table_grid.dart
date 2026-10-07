part of 'table_page.dart';

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
                    side: const BorderSide(
                      color: GlobalColors.billingCardBorder,
                    ),
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
          children: [
            ...header,
            Expanded(child: grid),
          ],
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

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table, this.onTap});

  final TableLayoutTable table;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRound =
        table.shape.toLowerCase().contains('round') ||
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
            border: Border.all(
              color: GlobalColors.billingCardBorder,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.table_restaurant_outlined,
                  color: GlobalColors.homeActionBackground,
                  size: 30,
                ),
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
        Icon(
          Icons.table_restaurant_outlined,
          size: 48,
          color: GlobalColors.secondaryText,
        ),
        SizedBox(height: 12),
        Text(
          'No active tables found',
          style: TextStyle(
            color: GlobalColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Sync table layouts, then refresh this page.',
          style: TextStyle(color: GlobalColors.secondaryText),
        ),
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
