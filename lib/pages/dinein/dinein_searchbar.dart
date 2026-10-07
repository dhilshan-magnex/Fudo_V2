part of 'dinein_page.dart';

class _MenuSearchBar extends StatelessWidget {
  const _MenuSearchBar({
    required this.categories,
    required this.selectedCategory,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onRefresh,
  });

  final List<DineInCategory> categories;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Menu',
              style: TextStyle(
                color: GlobalColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh menu',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
    ],
  );
}
