import 'package:flutter/material.dart';
import '../../../database/db_manager.dart';
import '../../../layout/layout.dart';
import '../../../utils/global_colors.dart';
import '../../../widgets/buttons/back_button.dart';

/// Menu browser used when a dine-in order is being created.
class DineInPage extends StatefulWidget {
  const DineInPage({super.key});

  @override
  State<DineInPage> createState() => _DineInPageState();
}

class _DineInPageState extends State<DineInPage> {
  late Future<_DineInData> _menuFuture;
  final _searchController = TextEditingController();
  final _menuScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _categoryCode;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _menuFuture = _loadMenu();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  void _jumpToCategory(String? code) {
    setState(() => _categoryCode = code);
    if (code == null) {
      if (_menuScrollController.hasClients) {
        _menuScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _categoryKeys[code]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  Future<_DineInData> _loadMenu() async {
    final database = await DBManager.getDatabase(AppDatabase.fudo);
    final results = await Future.wait([
      database.query('Menu_Items'),
      database.query('Category_Lvl1'),
    ]);
    final categories = results[1]
        .map(DineInCategory.fromRow)
        .where((category) => category.code.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final items = results[0]
        .map(DineInMenuItem.fromRow)
        .where((item) => item.id.isNotEmpty && item.isAvailableForDineIn)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _DineInData(categories, items);
  }

  void _refresh() => setState(() => _menuFuture = _loadMenu());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GlobalColors.homeBackground,
        body: HomeLayout(
          primaryContent: const _DineInHeader(),
          sideContent: FutureBuilder<_DineInData>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _MenuError(onRetry: _refresh);
              }
              final data = snapshot.data!;
              final visibleItems = data.items.where((item) {
                final matchesSearch = _query.isEmpty ||
                    item.name.toLowerCase().contains(_query) ||
                    item.longName.toLowerCase().contains(_query);
                return matchesSearch;
              }).toList();
              return _MenuContent(
                categories: data.categories,
                items: visibleItems,
                selectedCategory: _categoryCode,
                searchController: _searchController,
                onCategoryChanged: _jumpToCategory,
                onRefresh: _refresh,
                scrollController: _menuScrollController,
                categoryKeys: _categoryKeys,
              );
            },
          ),
        ),
      );
}

class _DineInHeader extends StatelessWidget {
  const _DineInHeader();

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
                    child: Text('FUDO V2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        )),
                  ),
                  SizedBox(
                    width: compact ? 96 : 112,
                    height: 56,
                    child: const FudoBackButton(),
                  ),
                ],
              ),
              SizedBox(height: compact ? 12 : 24),
              Text('Dine In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 26 : 32,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              const Text('Select items for the table order',
                  style: TextStyle(
                    color: GlobalColors.homeHeaderLabel,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          );
        },
      );
}

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
  });

  final List<DineInCategory> categories;
  final List<DineInMenuItem> items;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onRefresh;
  final ScrollController scrollController;
  final Map<String, GlobalKey> categoryKeys;

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
          );
          final controls = <Widget>[
            Row(children: [
              const Expanded(
                child: Text('Menu',
                    style: TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              IconButton(
                tooltip: 'Refresh menu',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ]),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search food or drinks',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: GlobalColors.billingCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: GlobalColors.billingCardBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  for (final category in categories) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(category.name),
                      selected: category.code == selectedCategory,
                      onSelected: (_) => onCategoryChanged(category.code),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ];
          if (!constraints.maxHeight.isFinite) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...controls, list],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...controls, Expanded(child: list)],
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
  });
  final List<DineInMenuItem> items;
  final List<DineInCategory> categories;
  final bool showCategorySections;
  final bool shrinkWrap;
  final ScrollController scrollController;
  final Map<String, GlobalKey> categoryKeys;

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
                  )
                : _CategoryMenuList(
                    groups: groups,
                    columns: columns,
                    controller: scrollController,
                    categoryKeys: categoryKeys,
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
            itemBuilder: (context, index) => _MenuTile(item: items[index]),
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
      final categoryItems =
          items.where((item) => item.categoryCode == category.code).toList();
      if (categoryItems.isNotEmpty) {
        groups.add(_MenuCategoryGroup(category.code, category.name, categoryItems));
        handledCodes.add(category.code);
      }
    }
    final uncategorized =
        items.where((item) => !handledCodes.contains(item.categoryCode)).toList();
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
  });
  final List<_MenuCategoryGroup> groups;
  final int columns;
  final ScrollController controller;
  final Map<String, GlobalKey> categoryKeys;

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
                  (context, index) => _MenuTile(item: group.items[index]),
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
  });
  final List<_MenuCategoryGroup> groups;
  final int columns;
  final Map<String, GlobalKey> categoryKeys;

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
              itemBuilder: (context, index) => _MenuTile(item: group.items[index]),
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
  const _MenuTile({required this.item});
  final DineInMenuItem item;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant_menu_rounded,
                    color: _colorFromCode(item.colorCode), size: 30),
                const Spacer(),
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GlobalColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 4),
                Text('Rs. ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: GlobalColors.homeActionBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      );
}

Color _colorFromCode(String value) {
  final hex = value.replaceAll('#', '').trim();
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? GlobalColors.homeActionBackground : Color(0xFF000000 | parsed);
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('No menu items found. Sync menu data and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlobalColors.secondaryText)),
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
      order: num.tryParse(row['Display_Order_ID']?.toString() ?? '')?.toInt() ?? 0,
      isAvailableForDineIn: dine == null || dine.isEmpty || dine == '1' || dine == 'true' || dine == 'yes',
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
