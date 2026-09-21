import '../api/applicense_api.dart';
import '../api/category_api.dart';
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

typedef ApiSyncHandler = Future<void> Function();

class ApiTableRoute {
  const ApiTableRoute({
    required this.dbType,
    required this.tableName,
    required this.sync,
    this.syncKey,
  });

  final AppDatabase dbType;
  final String tableName;
  final ApiSyncHandler sync;
  final String? syncKey;
}

class ApiRouteRegistry {
  static final Map<String, Future<void>> _runningSyncs = {};

  static Future<void> syncTable(AppDatabase dbType, String tableName) async {
    final route = _routeFor(dbType, tableName);

    if (route == null) {
      throw UnsupportedError(
        'No API route configured for ${dbType.name}.$tableName',
      );
    }

    final key = route.syncKey ?? _routeKey(route.dbType, route.tableName);
    final runningSync = _runningSyncs[key];
    if (runningSync != null) return runningSync;

    final sync = route.sync().whenComplete(() => _runningSyncs.remove(key));
    _runningSyncs[key] = sync;

    return sync;
  }

  static ApiTableRoute? _routeFor(AppDatabase dbType, String tableName) {
    return _routes[_routeKey(dbType, tableName)];
  }

  static String _routeKey(AppDatabase dbType, String tableName) {
    return '${dbType.name}.${tableName.trim().toLowerCase()}';
  }

  static final Map<String, ApiTableRoute> _routes = {
    _routeKey(AppDatabase.sys, 'App_License'): ApiTableRoute(
      dbType: AppDatabase.sys,
      tableName: 'App_License',
      sync: () async {
        await AppLicenseApi().syncAppLicense();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Category_Type'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Category_Type',
      syncKey: 'fudo.categories',
      sync: () async {
        await CategoryApi().syncCategories();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Category_Lvl1'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Category_Lvl1',
      syncKey: 'fudo.categories',
      sync: () async {
        await CategoryApi().syncCategories();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Category_Lvl2'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Category_Lvl2',
      syncKey: 'fudo.categories',
      sync: () async {
        await CategoryApi().syncCategories();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Category_Lvl3'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Category_Lvl3',
      syncKey: 'fudo.categories',
      sync: () async {
        await CategoryApi().syncCategories();
      },
    ),
    _routeKey(AppDatabase.fudo, 'CreditCard_Mast'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'CreditCard_Mast',
      sync: () async {
        await CreditCardMastApi().syncCreditCardMast();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Currency_Mast'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Currency_Mast',
      sync: () async {
        await CurrencyMastApi().syncCurrencyMast();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Discount_Mast'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Discount_Mast',
      sync: () async {
        await DiscountMastApi().syncDiscountMast();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Menu_Items'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Menu_Items',
      sync: () async {
        await MenuItemApi().syncMenuItems();
      },
    ),
    _routeKey(AppDatabase.fudo, 'More_Size'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'More_Size',
      sync: () async {
        await MoreSizesApi().syncMoreSizes();
      },
    ),
    _routeKey(AppDatabase.fudo, 'POS_Mast'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'POS_Mast',
      sync: () async {
        await PosMastApi().syncPosMast();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Section_Master'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Section_Master',
      sync: () async {
        await SectionMasterApi().syncSectionMaster();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Shop_Info'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Shop_Info',
      sync: () async {
        await ShopInfoApi().syncShopInfo();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Side_Items'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Side_Items',
      sync: () async {
        await SideItemsApi().syncSideItems();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Table_Layout'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Table_Layout',
      sync: () async {
        await TableLayoutApi().syncTableLayout();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Tax_Group'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Tax_Group',
      sync: () async {
        await TaxGroupApi().syncTaxGroup();
      },
    ),
    _routeKey(AppDatabase.fudo, 'Tax_Mast'): ApiTableRoute(
      dbType: AppDatabase.fudo,
      tableName: 'Tax_Mast',
      sync: () async {
        await TaxMasterApi().syncTaxMaster();
      },
    ),
  };
}
