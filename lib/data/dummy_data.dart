import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import '../core/config/server_settings.dart';
import '../functions/uservalidation/app_functions.dart';
import 'database/db_manager.dart';
import 'server/users_api.dart';
import 'server/usersetup_api.dart';
import 'server/customerdisplay_api.dart';
import 'server/cashdrawer_api.dart';
import 'server/posprinter_api.dart';

class DummyTableResult {
  DummyTableResult(this.table);

  final String table;
  int inserted = 0;
  int existing = 0;
  String status = 'Not attempted';

  String get summary =>
      '$inserted inserted, $existing already present. $status';
}


class DummyData {
  DummyData._();
  static const Map<String, List<Map<String, Object?>>> rows = {
    'User_Group': [
      {
        'Group_Code': 'ADMIN',
        'Group_Name': 'Demo Administrators',
        'Group_Descr': 'Demo billing and data sync access',
      },
      {
        'Group_Code': 'CASH',
        'Group_Name': 'Demo Cashiers',
        'Group_Descr': 'Demo billing access only',
      },
    ],
    'User_File': [
      {
        'User_ID': 'u02',
        'User_Name': 'admin',
        'User_Pwd': 'admin123',
        'Group_Code': 'ADMIN',
        'User_Active': 1,
      },
    ],
    'User_setup': [
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.billingScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.posSettingsScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.categoryScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.menuItemScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.systemSettingsScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.dashboardScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.reportsScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.posMachineScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.posAccessScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.discountScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.taxMasterScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.paymentScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.foreignCurrencyScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.creditCardScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.kotSetupScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.dayEndScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.kdsSetupScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.excScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.cashOutScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.changeWaiterScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.noPriceScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.adjustPaymentScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.cpayScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.payoutScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.dlScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.takeawayScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.saveScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.openCheckScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.cancelScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.splitScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.mergeScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.voidScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.discScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.complimentaryScreen,
        'Function_ID': AppFunctions.screenAccess,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.billingScreen,
        'Function_ID': AppFunctions.billing,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'ADMIN',
        'Screen_ID': AppFunctions.dataSyncScreen,
        'Function_ID': AppFunctions.dataSync,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'CASH',
        'Screen_ID': AppFunctions.billingScreen,
        'Function_ID': AppFunctions.billing,
        'Access_Lvl': 1,
      },
      {
        'Group_Code': 'CASH',
        'Screen_ID': AppFunctions.dataSyncScreen,
        'Function_ID': AppFunctions.dataSync,
        'Access_Lvl': 0,
      },
    ],
    'Print_Mast': [
      {
        'Printer_Code': 'PRN',
        'Printer_Name': 'Receipt Printer',
        'Printer_Path': '192.0.2.10',
        'Printer_Port': '9100',
        'Printer_Type': 'NETWORK',
        'Printer_Model': 'POS',
      },
    ],
    'Customer_Display': [
      {
        'Display_Code': 'DISP',
        'Display_Name': 'Customer Display',
        'Display_Port': 2,
        'Display_Type': 'SERIAL',
      },
    ],
    'Cash_Drawer': [
      {
        'Drawer_Code': 'DRAW',
        'Drawer_Name': 'Cash Drawer',
        'Drawer_Port': 'COM3',
        'Drawer_Type': 'SERIAL',
      },
    ],
  };

  static const _keys = {
    'User_Group': ['Group_Code'],
    'User_File': ['User_ID'],
    'User_setup': ['Group_Code', 'Screen_ID', 'Function_ID'],
    'Print_Mast': ['Printer_Code'],
    'Customer_Display': ['Display_Code'],
    'Cash_Drawer': ['Drawer_Code'],
  };

  static Future<int> insert({
    String? clientType,
    Database? database,
    http.Client? client,
    String? baseUrl,
    void Function(List<DummyTableResult>)? onResult,
  }) async {
    final results = {
      for (final table in rows.keys) table: DummyTableResult(table),
    };
    final server =
        DataSourceManager.getDataSource(clientType) == DataSource.api;
    try {
      if (server) {
        return await _insertOnServer(
          client: client,
          baseUrl: baseUrl,
          results: results,
        );
      }
      return await _insertLocally(database, results);
    } finally {
      onResult?.call(results.values.toList());
    }
  }

  static Future<int> _insertLocally(
    Database? database,
    Map<String, DummyTableResult> results,
  ) async {
    try {
      final db = database ?? await DBManager.getDatabase(AppDatabase.fudo);
      return await db.transaction((txn) async {
        var inserted = 0;
        for (final table in rows.entries) {
          final result = results[table.key]!;
          result.status = 'Failed while checking or inserting records';
          final keys = _keys[table.key]!;
          for (final row in table.value) {
            final existing = await txn.query(
              table.key,
              columns: keys,
              where: keys.map((key) => '"$key" = ?').join(' AND '),
              whereArgs: keys.map((key) => row[key]).toList(),
              limit: 1,
            );
            if (existing.isNotEmpty) {
              result.existing++;
              continue;
            }
            await txn.insert(table.key, row);
            inserted++;
            result.inserted++;
          }
          result.status = 'Complete';
        }
        return inserted;
      });
    } catch (_) {
      for (final result in results.values) {
        if (result.inserted > 0) {
          result.inserted = 0;
          result.status = 'Not saved: SQLite transaction rolled back';
        }
      }
      rethrow;
    }
  }

  static Future<int> _insertOnServer({
    http.Client? client,
    String? baseUrl,
    required Map<String, DummyTableResult> results,
  }) async {
    final address = (baseUrl ?? await ServerSettings.getBaseUrl() ?? '').trim();
    if (address.isEmpty) {
      throw StateError(
        'Enter the API server address before inserting dummy data.',
      );
    }
    final users = UsersApi(client: client, baseUrl: address);
    final groups = UserSetupApi(client: client, baseUrl: address);
    final displays = CustomerDisplayApi(client: client, baseUrl: address);
    final drawers = CashDrawerApi(client: client, baseUrl: address);
    final printers = PosPrinterApi(client: client, baseUrl: address);
    var inserted = 0;
    final failures = <String>[];

    // Read existing keys before each table so retries preserve successful rows.
    Future<void> insertMissing(
      String table,
      Future<List<Map<String, dynamic>>> Function() fetch,
      Future<void> Function(Map<String, Object?>) create,
    ) async {
      final result = results[table]!;
      try {
        result.status = 'Failed to check existing records';
        final keys = _keys[table]!;
        Map<String, Object?> serverRow(Map<String, Object?> row) {
          if (table == 'User_setup' &&
              (row['Function_ID'] as String).trim().isEmpty) {
            return {...row, 'Function_ID': row['Screen_ID']};
          }
          return row;
        }

        String recordKey(Map<String, Object?> row) {
          final fields = {
            for (final entry in row.entries)
              entry.key.toLowerCase(): entry.value,
          };
          return jsonEncode([
            for (final key in keys)
              fields[key.toLowerCase()]?.toString().trim().toUpperCase(),
          ]);
        }

        final existing = (await fetch()).map(recordKey).toSet();
        for (final sample in rows[table]!) {
          final row = serverRow(sample);
          final value = recordKey(row);
          if (existing.contains(value)) {
            result.existing++;
            continue;
          }
          result.status = 'Insert not confirmed; retry to check the server';
          try {
            await create(row);
          } on UserGroupAlreadyExistsException {
            final confirmed = (await fetch()).any(
              (record) => recordKey(record) == value,
            );
            if (!confirmed) rethrow;
            existing.add(value);
            result.existing++;
            continue;
          }
          existing.add(value);
          inserted++;
          result.inserted++;
        }
        result.status = 'Complete';
      } catch (error) {
        result.status = '${result.status}. $error';
        failures.add(table);
      }
    }

    await insertMissing('User_Group', groups.getUserGroups, (row) {
      return groups.createUserGroup(
        groupCode: row['Group_Code'] as String,
        groupName: row['Group_Name'] as String,
        groupDescr: row['Group_Descr'] as String,
      );
    });
    if (!failures.contains('User_Group')) {
      await insertMissing('User_File', users.getUsers, (row) {
        return users.createUser(
          userId: row['User_ID'] as String,
          userName: row['User_Name'] as String,
          groupCode: row['Group_Code'] as String,
          userPwd: row['User_Pwd'] as String,
          userActive: row['User_Active'] as int,
        );
      });
      await insertMissing(
        'User_setup',
        () async {
          final existing = <Map<String, dynamic>>[];
          final checked = <String>{};
          for (final row in rows['User_setup']!) {
            final groupCode = row['Group_Code'] as String;
            final screenId = row['Screen_ID'] as String;
            if (checked.add(jsonEncode([groupCode, screenId]))) {
              existing.addAll(
                await groups.getUserSetupByGroupScreen(
                  groupCode: groupCode,
                  screenId: screenId,
                ),
              );
            }
          }
          return existing;
        },
        (row) => groups.createUserSetup(
          groupCode: row['Group_Code'] as String,
          functionId: row['Function_ID'] as String,
          screenId: row['Screen_ID'] as String,
          accessLevel: row['Access_Lvl'] as int,
        ),
      );
    } else {
      results['User_setup']!.status =
          'Not attempted: user group setup failed. '
          '${results['User_Group']!.status}';
      results['User_File']!.status =
          'Not attempted: user group setup failed. '
          '${results['User_Group']!.status}';
    }
    await insertMissing('Print_Mast', printers.getPrinters, (row) {
      return printers.createPrinter(
        printerCode: row['Printer_Code'] as String,
        printerName: row['Printer_Name'] as String,
        printerPath: row['Printer_Path'] as String,
        printerPort: int.parse(row['Printer_Port'].toString()),
        printerType: row['Printer_Type'] as String,
        printerModel: row['Printer_Model'] as String,
      );
    });
    await insertMissing('Customer_Display', displays.getCustomerDisplays, (
      row,
    ) {
      return displays.createCustomerDisplay(
        displayCode: row['Display_Code'] as String,
        displayName: row['Display_Name'] as String,
        displayPort: row['Display_Port'] as int,
        displayType: row['Display_Type'] as String,
      );
    });
    await insertMissing('Cash_Drawer', drawers.getCashDrawers, (row) {
      return drawers.createCashDrawer(
        drawerCode: row['Drawer_Code'] as String,
        drawerName: row['Drawer_Name'] as String,
        drawerPort: row['Drawer_Port'] as String,
        drawerType: row['Drawer_Type'] as String,
      );
    });
    if (failures.isNotEmpty) {
      throw Exception(
        'Dummy data setup failed for: ${failures.join(', ')}. See table results for details.',
      );
    }
    return inserted;
  }
}
