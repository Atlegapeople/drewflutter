import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'vending_machine.db';
  static const int _dbVersion = 2;

  static Future<Database> get database async {
    if (_database == null) {
      // Initialize database factory for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        databaseFactory = databaseFactoryFfi;
      }
      _database = await _initDatabase();
    }
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rfid_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_uid TEXT UNIQUE NOT NULL,
        user_role TEXT NOT NULL,
        user_name TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_type TEXT UNIQUE NOT NULL,
        stock_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Dispense log table
    await db.execute('''
      CREATE TABLE dispense_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL,
        card_uid TEXT,
        product_type TEXT NOT NULL,
        dispensed_at TEXT NOT NULL
      )
    ''');

    // Insert default admin cards
    await db.insert('rfid_cards', {
      'card_uid': 'A955AF02',
      'user_role': 'admin',
      'user_name': 'Default Admin',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    // Insert Thabo's card
    await db.insert('rfid_cards', {
      'card_uid': '7a373b00',
      'user_role': 'user',
      'user_name': 'Thabo',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    // Initialize inventory with default stock
    await db.insert('inventory', {
      'product_type': 'tampon',
      'stock_count': 50,
    });
    await db.insert('inventory', {
      'product_type': 'pad',
      'stock_count': 50,
    });
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add inventory table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_type TEXT UNIQUE NOT NULL,
          stock_count INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Add dispense log table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dispense_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_name TEXT NOT NULL,
          card_uid TEXT,
          product_type TEXT NOT NULL,
          dispensed_at TEXT NOT NULL
        )
      ''');

      // Initialize inventory with default stock if not exists
      final tamponExists = await db.query('inventory', where: 'product_type = ?', whereArgs: ['tampon']);
      if (tamponExists.isEmpty) {
        await db.insert('inventory', {'product_type': 'tampon', 'stock_count': 50});
      }

      final padExists = await db.query('inventory', where: 'product_type = ?', whereArgs: ['pad']);
      if (padExists.isEmpty) {
        await db.insert('inventory', {'product_type': 'pad', 'stock_count': 50});
      }

      // Add Thabo's card if it doesn't exist
      final thaboExists = await db.query('rfid_cards', where: 'card_uid = ?', whereArgs: ['7a373b00']);
      if (thaboExists.isEmpty) {
        await db.insert('rfid_cards', {
          'card_uid': '7a373b00',
          'user_role': 'user',
          'user_name': 'Thabo',
          'created_at': DateTime.now().toIso8601String(),
          'is_active': 1,
        });
      }
    }
  }

  // Card management methods
  static Future<int> registerCard(String cardUid, String userRole, String? userName) async {
    final db = await database;
    return await db.insert('rfid_cards', {
      'card_uid': cardUid,
      'user_role': userRole,
      'user_name': userName,
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  }

  static Future<Map<String, dynamic>?> getCardByUid(String cardUid) async {
    final db = await database;
    final results = await db.query(
      'rfid_cards',
      where: 'card_uid = ? AND is_active = 1',
      whereArgs: [cardUid],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<List<Map<String, dynamic>>> getAllCards() async {
    final db = await database;
    return await db.query(
      'rfid_cards',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
  }

  static Future<int> deactivateCard(String cardUid) async {
    final db = await database;
    return await db.update(
      'rfid_cards',
      {'is_active': 0},
      where: 'card_uid = ?',
      whereArgs: [cardUid],
    );
  }

  static Future<bool> cardExists(String cardUid) async {
    final card = await getCardByUid(cardUid);
    return card != null;
  }

  // Inventory management methods
  static Future<int> getStockCount(String productType) async {
    final db = await database;
    final results = await db.query(
      'inventory',
      columns: ['stock_count'],
      where: 'product_type = ?',
      whereArgs: [productType],
    );
    return results.isNotEmpty ? results.first['stock_count'] as int : 0;
  }

  static Future<void> updateStockCount(String productType, int newCount) async {
    final db = await database;
    await db.update(
      'inventory',
      {'stock_count': newCount},
      where: 'product_type = ?',
      whereArgs: [productType],
    );
  }

  static Future<void> decrementStock(String productType) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE inventory SET stock_count = stock_count - 1 WHERE product_type = ? AND stock_count > 0',
      [productType],
    );
  }

  static Future<void> incrementStock(String productType, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE inventory SET stock_count = stock_count + ? WHERE product_type = ?',
      [quantity, productType],
    );
  }

  // Dispense logging methods
  static Future<int> logDispense(String userName, String? cardUid, String productType) async {
    final db = await database;
    return await db.insert('dispense_log', {
      'user_name': userName,
      'card_uid': cardUid,
      'product_type': productType,
      'dispensed_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getDispenseHistory({int limit = 100}) async {
    final db = await database;
    return await db.query(
      'dispense_log',
      orderBy: 'dispensed_at DESC',
      limit: limit,
    );
  }

  static Future<List<Map<String, dynamic>>> getUserDispenseHistory(String userName, {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'dispense_log',
      where: 'user_name = ?',
      whereArgs: [userName],
      orderBy: 'dispensed_at DESC',
      limit: limit,
    );
  }
}