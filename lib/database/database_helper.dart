import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/scan.dart';
import '../models/prediction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('cocoscan.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        scanned_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER NOT NULL,
        disease_class TEXT NOT NULL,
        confidence REAL NOT NULL,
        rank INTEGER NOT NULL,
        
        FOREIGN KEY (scan_id)
          REFERENCES scans (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertScan(
    Scan scan,
    List<Prediction> predictions,
  ) async {
    final db = await database;

    return await db.transaction<int>((transaction) async {
      final scanId = await transaction.insert(
        'scans',
        scan.toMap()..remove('id'),
      );

      for (final prediction in predictions) {
        await transaction.insert(
          'predictions',
          prediction.toMap()
            ..remove('id')
            ..['scan_id'] = scanId,
        );
      }

      return scanId;
    });
  }

  Future<List<Scan>> getAllScans() async {
    final db = await database;

    final result = await db.query(
      'scans',
      orderBy: 'scanned_at DESC',
    );

    return result.map((map) {
      return Scan.fromMap(map);
    }).toList();
  }

  Future<Scan?> getScan(int scanId) async {
    final db = await database;

    final result = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [scanId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Scan.fromMap(result.first);
  }

  Future<List<Prediction>> getPredictions(
    int scanId,
  ) async {
    final db = await database;

    final result = await db.query(
      'predictions',
      where: 'scan_id = ?',
      whereArgs: [scanId],
      orderBy: 'rank ASC',
    );

    return result.map((map) {
      return Prediction.fromMap(map);
    }).toList();
  }

  Future<void> deleteScan(int scanId) async {
    final db = await database;

    await db.delete(
      'predictions',
      where: 'scan_id = ?',
      whereArgs: [scanId],
    );

    await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}