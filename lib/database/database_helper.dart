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
  final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

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
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }

  static Future<bool> validateLogin(String userId, String password) async {
  final db = await database;
  final result = await db.query(
    'User_File', // replace with actual table name
    where: 'User_Name = ? AND User_Pwd = ? AND User_Active = ?',
    whereArgs: [userId, password, 1],
  );

  if (result.isEmpty) return false;

  final storedHash = result.first['User_Pwd'] as String;
  return BCrypt.checkpw(password, storedHash);
  
}
}