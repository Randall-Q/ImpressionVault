import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/customer.dart';
import '../models/customer_image_record.dart';
import '../models/customer_summary.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _openDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported with this SQLite setup.');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory docsDirectory = await getApplicationDocumentsDirectory();
    final String databasePath = p.join(docsDirectory.path, 'impression_vault.db');

    return openDatabase(
      databasePath,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            email TEXT NOT NULL,
            birthdate TEXT,
            sex TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE customer_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<int> upsertCustomer(Customer customer) async {
    final Database db = await database;

    if (customer.id == null) {
      return db.insert('customers', customer.toMap()..remove('id'));
    }

    final Map<String, dynamic> updateMap = customer.toMap()
      ..remove('id')
      ..remove('created_at');

    await db.update(
      'customers',
      updateMap,
      where: 'id = ?',
      whereArgs: <Object?>[customer.id],
    );
    return customer.id!;
  }

  Future<void> touchCustomer(int customerId) async {
    final Database db = await database;
    await db.update(
      'customers',
      <String, Object?>{'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: <Object?>[customerId],
    );
  }

  Future<Customer?> getCustomer(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Customer.fromMap(rows.first);
  }

  Future<List<CustomerSummary>> listCustomerSummaries() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT
        c.id,
        c.name,
        c.email,
        c.sex,
        c.birthdate,
        COUNT(ci.id) AS image_count
      FROM customers c
      LEFT JOIN customer_images ci ON ci.customer_id = c.id
      GROUP BY c.id
      ORDER BY c.updated_at DESC
    ''');

    return rows
        .map((Map<String, Object?> row) =>
            CustomerSummary.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<int> addCustomerImage(CustomerImageRecord imageRecord) async {
    final Database db = await database;
    return db.insert('customer_images', imageRecord.toMap()..remove('id'));
  }

  Future<List<CustomerImageRecord>> listImagesForCustomer(int customerId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'customer_images',
      where: 'customer_id = ?',
      whereArgs: <Object?>[customerId],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((Map<String, Object?> row) =>
            CustomerImageRecord.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> deleteImage(int imageId) async {
    final Database db = await database;
    await db.delete(
      'customer_images',
      where: 'id = ?',
      whereArgs: <Object?>[imageId],
    );
  }
}
