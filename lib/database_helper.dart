import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'app_database.db');
  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) {
      db.execute('''
        CREATE TABLE members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cifkey TEXT NOT NULL,
          name TEXT,
          imagePath TEXT,
          signature BLOB
        )
      ''');
    },
  );
}

 Future<int> insertMember(Map<String, dynamic> data) async {
  final db = await database;

  // Ensure null-safe insertion
  final sanitizedData = {
    'cifkey': data['cifkey'],
    'name': data['name'] ?? '',
    'imagePath': data['imagePath'] ?? null,
    'signature': data['signature'] ?? null,
  };

  return await db.insert('members', sanitizedData);
}

Future<int> updateMember(String cifKey, Map<String, dynamic> data) async {
  final db = await database;

  // Ensure null-safe update
  final sanitizedData = {
    'name': data['name'] ?? '',
    'imagePath': data['imagePath'] ?? null,
    'signature': data['signature'] ?? null,
  };

  // Update the member where the CIF Key matches
  return await db.update(
    'members',
    sanitizedData,
    where: 'cifkey = ?',
    whereArgs: [cifKey],
  );
}

  Future<List<Map<String, dynamic>>> getMembers() async {
    Database db = await database;
    print('Fetching all members'); // Log fetch
    return await db.query('members');
  }

  Future<Map<String, dynamic>?> getMemberByCIFKey(String cifKey) async {
  final db = await database;
  final List<Map<String, dynamic>> result = await db.query(
    'members',
    where: 'cifkey = ?',
    whereArgs: [cifKey],
  );
  return result.isNotEmpty ? result.first : null;
}

  Future<void> verifySchema() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery("PRAGMA table_info(members)");
    print("Table schema for 'members': $result");
  }
}
