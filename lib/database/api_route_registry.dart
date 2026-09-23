import '../api/applicense_api.dart';
import '../api/category_api.dart';
import '../api/catlvl_api.dart';
import '../api/creditcardmast_api.dart';
import '../api/currencymast_api.dart';
import '../api/discountmast_api.dart';
import '../api/menuitem_api.dart';
import '../api/moresizes_api.dart';
import '../api/posmast_api.dart';
import '../api/sectionmaster_api.dart';
import '../api/shopinfo_api.dart';
import '../api/sideitems_api.dart';
import '../api/tablelayout_api.dart';
import '../api/taxgroup_api.dart';
import '../api/taxmaster_api.dart';
import 'db_manager.dart';

typedef ApiSyncProgressHandler = void Function(
  ApiSyncProgress progress,
);

class ApiRouteRegistry {
  static const Duration syncTimeout =
      Duration(minutes: 2);

  static const int totalSyncCount = 15;

  static Future<void> syncTable(
    AppDatabase dbType,
    String tableName, {
    bool clearExistingData = false,
  }) async {
    final normalizedTableName = tableName.trim();
    if (normalizedTableName.isEmpty) {
      throw Exception('A table name is required for API sync.');
    }

    final normalizedKey = normalizedTableName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toLowerCase();

    switch (normalizedKey) {
      case 'applicense':
        await AppLicenseApi().syncAppLicense(
          clearExistingData: clearExistingData,
        );
        return;

      case 'categorytype':
      case 'categorylvl1':
      case 'categorylvl2':
      case 'categorylvl3':
        await CategoryApi().syncCategories(
          clearExistingData: clearExistingData,
        );
        return;

      case 'catlvl1':
      case 'catlvl2':
        await CatLvlApi().syncCatLevels(
          clearExistingData: clearExistingData,
        );
        return;

      case 'creditcardmast':
        await CreditCardMastApi().syncCreditCardMast(
          clearExistingData: clearExistingData,
        );
        return;

      case 'currencymast':
        await CurrencyMastApi().syncCurrencyMast(
          clearExistingData: clearExistingData,
        );
        return;

      case 'discountmast':
        await DiscountMastApi().syncDiscountMast(
          clearExistingData: clearExistingData,
        );
        return;

      case 'menuitem':
      case 'menuitems':
        await MenuItemApi().syncMenuItems(
          clearExistingData: clearExistingData,
        );
        return;

      case 'moresizes':
        await MoreSizesApi().syncMoreSizes(
          clearExistingData: clearExistingData,
        );
        return;

      case 'posmast':
        await PosMastApi().syncPosMast(
          clearExistingData: clearExistingData,
        );
        return;

      case 'sectionmaster':
        await SectionMasterApi().syncSectionMaster(
          clearExistingData: clearExistingData,
        );
        return;

      case 'shopinfo':
        await ShopInfoApi().syncShopInfo(
          clearExistingData: clearExistingData,
        );
        return;

      case 'sideitems':
        await SideItemsApi().syncSideItems(
          clearExistingData: clearExistingData,
        );
        return;

      case 'tablelayout':
        await TableLayoutApi().syncTableLayout(
          clearExistingData: clearExistingData,
        );
        return;

      case 'taxgroup':
        await TaxGroupApi().syncTaxGroup(
          clearExistingData: clearExistingData,
        );
        return;

      case 'taxmaster':
      case 'taxmast':
        await TaxMasterApi().syncTaxMaster(
          clearExistingData: clearExistingData,
        );
        return;

      default:
        throw Exception(
          'No API route is registered for table "$tableName" in database "$dbType".',
        );
    }
  }

  static Future<ApiSyncResult> syncAll({
    ApiSyncProgressHandler? onProgress,
    bool clearExistingData = false,
  }) async {
    var completedCount = 0;

    Future<void> reportProgress(
      String tableName, {
      bool isCompleted = false,
    }) async {
      onProgress?.call(
        ApiSyncProgress(
          completedCount: completedCount,
          totalCount: totalSyncCount,
          tableName: tableName,
          isCompleted: isCompleted,
        ),
      );
    }

    try {
      // --------------------------------------------------
      // 1. APP LICENSE
      // --------------------------------------------------

      await reportProgress('App License');

      final appLicenseResult =
          await AppLicenseApi()
              .syncAppLicense(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('App License');

      // --------------------------------------------------
      // 2. CATEGORIES
      // --------------------------------------------------

      await reportProgress('Categories');

      final categoryResult =
          await CategoryApi()
              .syncCategories(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Categories');

      // --------------------------------------------------
      // 3. CATEGORY LEVELS
      // --------------------------------------------------

      await reportProgress('Category Levels');

      final catLvlResult =
          await CatLvlApi()
              .syncCatLevels(
                clearExistingData: false,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Category Levels');

      // --------------------------------------------------
      // 4. CREDIT CARD MAST
      // --------------------------------------------------

      await reportProgress('Credit Cards');

      final creditCardResult =
          await CreditCardMastApi()
              .syncCreditCardMast(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Credit Cards');

      // --------------------------------------------------
      // 5. CURRENCY MAST
      // --------------------------------------------------

      await reportProgress('Currencies');

      final currencyResult =
          await CurrencyMastApi()
              .syncCurrencyMast(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Currencies');

      // --------------------------------------------------
      // 6. DISCOUNT MAST
      // --------------------------------------------------

      await reportProgress('Discounts');

      final discountResult =
          await DiscountMastApi()
              .syncDiscountMast(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Discounts');

      // --------------------------------------------------
      // 7. MENU ITEMS
      // --------------------------------------------------

      await reportProgress('Menu Items');

      final menuItemResult =
          await MenuItemApi()
              .syncMenuItems(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Menu Items');

      // --------------------------------------------------
      // 8. MORE SIZES
      // --------------------------------------------------

      await reportProgress('More Sizes');

      final moreSizesResult =
          await MoreSizesApi()
              .syncMoreSizes(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('More Sizes');

      // --------------------------------------------------
      // 9. POS MAST
      // --------------------------------------------------

      await reportProgress('POS Master');

      final posMastResult =
          await PosMastApi()
              .syncPosMast(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('POS Master');

      // --------------------------------------------------
      // 10. SECTION MASTER
      // --------------------------------------------------

      await reportProgress('Sections');

      final sectionResult =
          await SectionMasterApi()
              .syncSectionMaster(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Sections');

      // --------------------------------------------------
      // 11. SHOP INFO
      // --------------------------------------------------

      await reportProgress('Shop Information');

      final shopInfoResult =
          await ShopInfoApi()
              .syncShopInfo(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Shop Information');

      // --------------------------------------------------
      // 12. SIDE ITEMS
      // --------------------------------------------------

      await reportProgress('Side Items');

      final sideItemsResult =
          await SideItemsApi()
              .syncSideItems(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Side Items');

      // --------------------------------------------------
      // 13. TABLE LAYOUT
      // --------------------------------------------------

      await reportProgress('Table Layout');

      final tableLayoutResult =
          await TableLayoutApi()
              .syncTableLayout(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Table Layout');

      // --------------------------------------------------
      // 14. TAX GROUP
      // --------------------------------------------------

      await reportProgress('Tax Groups');

      final taxGroupResult =
          await TaxGroupApi()
              .syncTaxGroup(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress('Tax Groups');

      // --------------------------------------------------
      // 15. TAX MASTER
      // --------------------------------------------------

      await reportProgress('Tax Master');

      final taxMasterResult =
          await TaxMasterApi()
              .syncTaxMaster(
                clearExistingData: clearExistingData,
              )
              .timeout(syncTimeout);

      completedCount++;

      await reportProgress(
        'Tax Master',
        isCompleted: true,
      );

      return ApiSyncResult(
        appLicense: appLicenseResult,
        categories: categoryResult,
        catLevels: catLvlResult,
        creditCards: creditCardResult,
        currencies: currencyResult,
        discounts: discountResult,
        menuItems: menuItemResult,
        moreSizes: moreSizesResult,
        posMast: posMastResult,
        sections: sectionResult,
        shopInfo: shopInfoResult,
        sideItems: sideItemsResult,
        tableLayout: tableLayoutResult,
        taxGroups: taxGroupResult,
        taxMaster: taxMasterResult,
      );
    } catch (error) {
      throw Exception(
        'Data synchronization failed: $error',
      );
    }
  }
}

class ApiSyncProgress {
  const ApiSyncProgress({
    required this.completedCount,
    required this.totalCount,
    required this.tableName,
    required this.isCompleted,
  });

  final int completedCount;
  final int totalCount;
  final String tableName;
  final bool isCompleted;

  double get value {
    if (totalCount == 0) {
      return 0;
    }

    return completedCount / totalCount;
  }

  String get displayName => tableName;
}

class ApiSyncResult {
  const ApiSyncResult({
    required this.appLicense,
    required this.categories,
    required this.catLevels,
    required this.creditCards,
    required this.currencies,
    required this.discounts,
    required this.menuItems,
    required this.moreSizes,
    required this.posMast,
    required this.sections,
    required this.shopInfo,
    required this.sideItems,
    required this.tableLayout,
    required this.taxGroups,
    required this.taxMaster,
  });

  final AppLicenseSyncResult appLicense;
  final CategorySyncResult categories;
  final CatLvlSyncResult catLevels;
  final CreditCardMastSyncResult creditCards;
  final CurrencyMastSyncResult currencies;
  final DiscountMastSyncResult discounts;
  final MenuItemSyncResult menuItems;
  final MoreSizesSyncResult moreSizes;
  final PosMastSyncResult posMast;
  final SectionMasterSyncResult sections;
  final ShopInfoSyncResult shopInfo;
  final SideItemsSyncResult sideItems;
  final TableLayoutSyncResult tableLayout;
  final TaxGroupSyncResult taxGroups;
  final TaxMasterSyncResult taxMaster;
}