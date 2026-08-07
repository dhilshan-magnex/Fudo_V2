import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

String hashPassword(String plainPassword) {
  return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
}

class DBHelper {
  static Future<void> addUser({
    required String userId,
    required String userName,
    required String password,
    required String groupCode,
  }) async {
    final db = await database;
    final hashedPassword = hashPassword(password);

    

    await db.insert(
      'User_File',
      {
        'User_ID': userId,
        'User_Name': userName,
        'User_Pwd': hashedPassword,
        'Group_Code': groupCode,
        'User_Active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateUserPassword({
    required String userName,
    required String password,
  }) async {
    final db = await database;
    final hashedPassword = hashPassword(password);

    await db.update(
      'User_File',
      {'User_Pwd': hashedPassword},
      where: 'User_Name = ?',
      whereArgs: [userName],
    );
  }

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'Fudo.db');

    final exists = await databaseExists(path);
    if (!exists) {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/database/Fudo.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path);
    await _ensureDefaultAdminUser(db);
    return db;
  }

  static Future<void> _ensureDefaultAdminUser(Database db) async {
    const userName = 'admin';
    const password = 'admin123';

    final result = await db.query(
      'User_File',
      where: 'User_Name = ?',
      whereArgs: [userName],
      limit: 1,
    );

    if (result.isEmpty) {
      await db.insert('User_File', {
        'User_ID': '001',
        'User_Name': userName,
        'User_Pwd': hashPassword(password),
        'Group_Code': 'ADMIN',
        'User_Active': 1,
      });
      return;
    }

    final storedPassword = result.first['User_Pwd'] as String;
    final isBcryptHash = storedPassword.startsWith(r'$2');

    if (!isBcryptHash) {
      await db.update(
        'User_File',
        {'User_Pwd': hashPassword(storedPassword)},
        where: 'User_Name = ?',
        whereArgs: [userName],
      );
    }
  }

  static Future<bool> validateLogin(String userId, String password) async {
    final db = await database;
    final result = await db.query(
      'User_File',
      where: 'User_Name = ? AND User_Active = ?',
      whereArgs: [userId, 1],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final storedHash = result.first['User_Pwd'] as String;
    return BCrypt.checkpw(password, storedHash);
  }
}
