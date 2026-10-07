part of 'dinein_page.dart';

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.categories,
    required this.items,
    required this.selectedCategory,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onRefresh,
    required this.scrollController,
    required this.categoryKeys,
    required this.onAddToCart,
  });

  final List<DineInCategory> categories;
  final List<DineInMenuItem> items;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onRefresh;
  final ScrollController scrollController;
  final Map<String, GlobalKey> categoryKeys;
  final ValueChanged<DineInMenuItem> onAddToCart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final list = _MenuGrid(
        items: items,
        categories: categories,
        showCategorySections: true,
        shrinkWrap: !constraints.maxHeight.isFinite,
        scrollController: scrollController,
        categoryKeys: categoryKeys,
        onAddToCart: onAddToCart,
      );
      final controls = <Widget>[
        _MenuSearchBar(
          categories: categories,
          selectedCategory: selectedCategory,
          searchController: searchController,
          onCategoryChanged: onCategoryChanged,
          onRefresh: onRefresh,
        ),
      ];
      if (!constraints.maxHeight.isFinite) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...controls, list],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...controls,
          Expanded(child: list),
        ],
      );
    },
  );
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.items,
    required this.categories,
    required this.showCategorySections,
    required this.shrinkWrap,
    required this.scrollController,
    required this.categoryKeys,
    required this.onAddToCart,
  });
  final List<DineInMenuItem> items;
  final List<DineInCategory> categories;
  final bool showCategorySections;
  final bool shrinkWrap;
  final ScrollController scrollController;
  final Map<String, GlobalKey> categoryKeys;
  final ValueChanged<DineInMenuItem> onAddToCart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (items.isEmpty) return const _EmptyMenu();
      final columns = _columnsFor(constraints.maxWidth);
      if (showCategorySections) {
        final groups = _groups();
        return shrinkWrap
            ? _CategoryMenuColumn(
                groups: groups,
                columns: columns,
                categoryKeys: categoryKeys,
                onAddToCart: onAddToCart,
              )
            : _CategoryMenuList(
                groups: groups,
                columns: columns,
                controller: scrollController,
                categoryKeys: categoryKeys,
                onAddToCart: onAddToCart,
              );
      }
      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.18,
        ),
        itemBuilder: (context, index) =>
            _MenuTile(item: items[index], onAddToCart: onAddToCart),
      );
    },
  );

  int _columnsFor(double width) => width >= 900
      ? 4
      : width >= 560
      ? 3
      : 2;

  List<_MenuCategoryGroup> _groups() {
    final groups = <_MenuCategoryGroup>[];
    final handledCodes = <String>{};
    for (final category in categories) {
      final categoryItems = items
          .where((item) => item.categoryCode == category.code)
          .toList();
      if (categoryItems.isNotEmpty) {
        groups.add(
          _MenuCategoryGroup(category.code, category.name, categoryItems),
        );
        handledCodes.add(category.code);
      }
    }
    final uncategorized = items
        .where((item) => !handledCodes.contains(item.categoryCode))
        .toList();
    if (uncategorized.isNotEmpty) {
      groups.add(_MenuCategoryGroup('', 'Other', uncategorized));
    }
    return groups;
  }
}

class _CategoryMenuList extends StatelessWidget {
  const _CategoryMenuList({
    required this.groups,
    required this.columns,
    required this.controller,
    required this.categoryKeys,
    required this.onAddToCart,
  });
  final List<_MenuCategoryGroup> groups;
  final int columns;
  final ScrollController controller;
  final Map<String, GlobalKey> categoryKeys;
  final ValueChanged<DineInMenuItem> onAddToCart;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: controller,
    slivers: [
      for (final group in groups) ...[
        SliverToBoxAdapter(
          child: _CategoryHeading(
            key: categoryKeys.putIfAbsent(group.code, () => GlobalKey()),
            name: group.name,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _MenuTile(item: group.items[index], onAddToCart: onAddToCart),
              childCount: group.items.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.18,
            ),
          ),
        ),
      ],
    ],
  );
}

class _CategoryMenuColumn extends StatelessWidget {
  const _CategoryMenuColumn({
    required this.groups,
    required this.columns,
    required this.categoryKeys,
    required this.onAddToCart,
  });
  final List<_MenuCategoryGroup> groups;
  final int columns;
  final Map<String, GlobalKey> categoryKeys;
  final ValueChanged<DineInMenuItem> onAddToCart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final group in groups) ...[
        _CategoryHeading(
          key: categoryKeys.putIfAbsent(group.code, () => GlobalKey()),
          name: group.name,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) =>
              _MenuTile(item: group.items[index], onAddToCart: onAddToCart),
        ),
        const SizedBox(height: 24),
      ],
    ],
  );
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      name,
      style: const TextStyle(
        color: GlobalColors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MenuCategoryGroup {
  _MenuCategoryGroup(this.code, this.name, this.items);
  final String code;
  final String name;
  final List<DineInMenuItem> items;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onAddToCart});
  final DineInMenuItem item;
  final ValueChanged<DineInMenuItem> onAddToCart;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: () => onAddToCart(item),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              color: _colorFromCode(item.colorCode),
              size: 30,
            ),
            const Spacer(),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GlobalColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: GlobalColors.homeActionBackground,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _colorFromCode(String value) {
  final hex = value.replaceAll('#', '').trim();
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null
      ? GlobalColors.homeActionBackground
      : Color(0xFF000000 | parsed);
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'No menu items found. Sync menu data and try again.',
      textAlign: TextAlign.center,
      style: TextStyle(color: GlobalColors.secondaryText),
    ),
  );
}

class _MenuError extends StatelessWidget {
  const _MenuError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Could not load menu. Retry'),
    ),
  );
}

class _DineInData {
  const _DineInData(this.categories, this.items);
  final List<DineInCategory> categories;
  final List<DineInMenuItem> items;
}

class DineInCategory {
  const DineInCategory(this.code, this.name, this.order);
  factory DineInCategory.fromRow(Map<String, dynamic> row) {
    final code = row['Cat_Code']?.toString().trim() ?? '';
    final name = row['Cat_Name']?.toString().trim() ?? '';
    return DineInCategory(
      code,
      name.isEmpty ? code : name,
      num.tryParse(row['Display_Order_ID']?.toString() ?? '')?.toInt() ?? 0,
    );
  }
  final String code;
  final String name;
  final int order;
}

class DineInMenuItem {
  const DineInMenuItem({
    required this.id,
    required this.name,
    required this.longName,
    required this.categoryCode,
    required this.price,
    required this.colorCode,
    required this.order,
    required this.isAvailableForDineIn,
  });
  factory DineInMenuItem.fromRow(Map<String, dynamic> row) {
    final dine = row['Dine']?.toString().trim().toLowerCase();
    return DineInMenuItem(
      id: row['Menu_ID']?.toString().trim() ?? '',
      name: row['Menu_Name']?.toString().trim() ?? '',
      longName: row['Menu_Long_Name']?.toString().trim() ?? '',
      categoryCode: row['Cat_Code']?.toString().trim() ?? '',
      price: num.tryParse(row['Menu_Price']?.toString() ?? '')?.toDouble() ?? 0,
      colorCode: row['Color_Code']?.toString() ?? '',
      order:
          num.tryParse(row['Display_Order_ID']?.toString() ?? '')?.toInt() ?? 0,
      isAvailableForDineIn:
          dine == null ||
          dine.isEmpty ||
          dine == '1' ||
          dine == 'true' ||
          dine == 'yes',
    );
  }
  final String id;
  final String name;
  final String longName;
  final String categoryCode;
  final double price;
  final String colorCode;
  final int order;
  final bool isAvailableForDineIn;
}
