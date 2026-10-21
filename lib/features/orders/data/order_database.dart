import 'package:sqflite/sqflite.dart';
import 'package:fudo_v2/data/database/db_manager.dart';

/// Access to the existing transaction database. Order headers are stored in
/// Fudo.db's Tran_Header table; this class deliberately creates no database.
class OrderDatabase {
  Future<Database> get database => DBManager.getDatabase(AppDatabase.fudo);
}
