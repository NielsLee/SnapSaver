import 'package:path/path.dart';
import 'package:snap_saver/constants.dart';
import 'package:sqflite/sqflite.dart';

import '../entity/saver.dart';

class SaverDatabase {
  late Database _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_isInitialized) return _database;

    _database = await _init();
    _isInitialized = true;
    return _database;
  }

  Future<int> insertSaver(Saver saver) async {
    final db = await database;

    return db.insert(Constants.tableName, saver.toMap(),
        conflictAlgorithm: ConflictAlgorithm.rollback);
  }

  Future<void> deleteSaver(Saver saver) async {
    final db = await database;

    db.delete(Constants.tableName, where: 'path = ?', whereArgs: [saver.path]);
  }

  Future<List<Saver>> getAllSavers() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(Constants.tableName);

    return List.generate(maps.length, (i) {
      return Saver(
          path: maps[i]['path'],
          name: maps[i]['name'],
          color: maps[i]['color']);
    });
  }

  Future<Database> _init() async {
    return openDatabase(
      join(await getDatabasesPath(), Constants.dbName),
      version: Constants.dbVersion,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE ${Constants.tableName}(
            path TEXT PRIMARY KEY,
            name TEXT,
            color TEXT DEFAULT NULL
          )
          ''',
        );
      },
      onUpgrade: _onUpgrade,
      onDowngrade: (db, oldVersion, newVersion) {},
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1) {
      _1_2(db);
    }
  }

  Future<void> _1_2(Database db) async {
    await db.execute(
        'ALTER TABLE ${Constants.tableName} ADD COLUMN color TEXT DEFAULT NULL');

    await db.execute('''
        CREATE TABLE saver_paths(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          saver_name TEXT,
          path TEXT,
          FOREIGN KEY(saver_name) REFERENCES ${Constants.tableName}(name)
        )
      ''');

    final List<Map<String, dynamic>> existingData =
        await db.query(Constants.tableName);
    for (var row in existingData) {
      await db.insert(
        'saver_paths',
        {'saver_name': row['name'], 'path': row['path']},
      );
    }
  }
}
