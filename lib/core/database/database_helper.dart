import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows/Desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // เก็บ Database ไว้ที่โฟลเดอร์ My Documents / SafetySuperapp
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbFolder = Directory('${appDocDir.path}\\SafetySuperapp');
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    
    final dbPath = join(dbFolder.path, 'safety_superapp_v1.db');
    debugPrint('Database Path: $dbPath');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. ตารางเก็บข้อมูลเหตุการณ์ (Near Miss & Incident)
    await db.execute('''
      CREATE TABLE safety_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        event_date TEXT NOT NULL,
        location TEXT,
        description TEXT NOT NULL,
        initial_risk_level TEXT,
        reported_by_id INTEGER,
        image_path TEXT,
        status TEXT DEFAULT 'OPEN',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. ตารางการวิเคราะห์สาเหตุรากเหง้า (RCA)
    await db.execute('''
      CREATE TABLE rca_analysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        method_used TEXT NOT NULL,
        root_cause_summary TEXT NOT NULL,
        analyzed_by_id INTEGER,
        analyzed_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES safety_events(id) ON DELETE CASCADE
      )
    ''');

    // 3. ตาราง Action Tracker (ศูนย์กลางติดตามมาตรการแก้ไข)
    await db.execute('''
      CREATE TABLE action_trackers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_module TEXT NOT NULL,
        source_id INTEGER NOT NULL,
        action_description TEXT NOT NULL,
        responsible_person TEXT,
        due_date TEXT NOT NULL,
        status TEXT DEFAULT 'OPEN',
        completed_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}
