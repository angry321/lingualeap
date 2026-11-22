import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/material_item.dart';
import '../models/word_item.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  static Future<void> initializeFfiIfNeeded() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lingualeap.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(appDocDir.path, 'LinguaLeap', filePath);
      final dir = Directory(p.dirname(dbPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Materials table
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        source_type TEXT NOT NULL,
        youtube_id TEXT,
        segments_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Words table
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lemma TEXT UNIQUE NOT NULL,
        original_form TEXT NOT NULL,
        translation TEXT NOT NULL,
        part_of_speech TEXT,
        explanation TEXT,
        context_sentence TEXT,
        status TEXT NOT NULL,
        next_review_at INTEGER NOT NULL,
        interval_days INTEGER DEFAULT 0,
        ease_factor REAL DEFAULT 2.5
      )
    ''');

    // Create index for fast lemma lookups
    await db.execute('''
      CREATE INDEX idx_words_lemma ON words(lemma)
    ''');
  }

  // --- Material CRUD ---

  Future<int> insertMaterial(MaterialItem item) async {
    final db = await database;
    return await db.insert('materials', item.toMap());
  }

  Future<List<MaterialItem>> getMaterials() async {
    final db = await database;
    final maps = await db.query('materials', orderBy: 'created_at DESC');
    return maps.map((map) => MaterialItem.fromMap(map)).toList();
  }

  Future<MaterialItem?> getMaterialById(int id) async {
    final db = await database;
    final maps = await db.query(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MaterialItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Word CRUD ---

  Future<int> insertOrUpdateWord(WordItem word) async {
    final db = await database;
    final normalizedLemma = word.lemma.toLowerCase().trim();

    return await db.insert(
      'words',
      word.copyWith(lemma: normalizedLemma).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WordItem?> getWordByLemma(String lemma) async {
    final db = await database;
    final normalizedLemma = lemma.toLowerCase().trim();
    final maps = await db.query(
      'words',
      where: 'lemma = ?',
      whereArgs: [normalizedLemma],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WordItem.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, WordItem>> getWordsMap() async {
    final db = await database;
    final maps = await db.query('words');
    final map = <String, WordItem>{};
    for (final row in maps) {
      final item = WordItem.fromMap(row);
      map[item.lemma.toLowerCase().trim()] = item;
    }
    return map;
  }

  Future<List<WordItem>> getAllWords({String? statusFilter, String? searchQuery}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (statusFilter != null && statusFilter != 'all') {
      conditions.add('status = ?');
      args.add(statusFilter);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(lemma LIKE ? OR original_form LIKE ? OR translation LIKE ?)');
      final pattern = '%${searchQuery.trim().toLowerCase()}%';
      args.addAll([pattern, pattern, pattern]);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
      whereArgs = args;
    }

    final maps = await db.query(
      'words',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'next_review_at ASC, id DESC',
    );
    return maps.map((map) => WordItem.fromMap(map)).toList();
  }

  Future<List<WordItem>> getWordsDueForReview() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      'words',
      where: 'status = ? AND next_review_at <= ?',
      whereArgs: ['learning', now],
      orderBy: 'next_review_at ASC',
    );
    return maps.map((map) => WordItem.fromMap(map)).toList();
  }

  Future<int> deleteWord(String lemma) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'lemma = ?',
      whereArgs: [lemma.toLowerCase().trim()],
    );
  }

  Future<int> deleteWordById(int id) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
