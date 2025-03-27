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

  Future<int> insertMember(Map<String, dynamic> member) async {
    try {
      Database db = await database;

      // Log the data being inserted for debugging
      if (kDebugMode) {
        print('Inserting member: $member');
      }

      // Insert the member data into the 'members' table
      int id = await db.insert('members', member);

      // Log the success of the insertion
      if (kDebugMode) {
        print('Member inserted with ID: $id');
      }

      return id;
    } catch (e) {
      // Log any errors that occur during insertion
      if (kDebugMode) {
        print('Error inserting member: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMembers() async {
    Database db = await database;
    print('Fetching all members'); // Log fetch
    return await db.query('members');
  }

  Future<Map<String, dynamic>?> getMemberByCIFKey(String cifkey) async {
    Database db = await database;
    print('Fetching member with CIF key: $cifkey'); // Log fetch
    List<Map<String, dynamic>> result = await db.query(
      'members',
      where: 'cifkey = ?',
      whereArgs: [cifkey],
    );
    if (result.isNotEmpty) {
      print('Member found: ${result.first}');
      return result.first;
    }
    print('No member found with CIF key: $cifkey');
    return null;
  }

  Future<void> verifySchema() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery("PRAGMA table_info(members)");
    print("Table schema for 'members': $result");
  }
}