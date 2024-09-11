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

    return db.insert(Constants.tableName, saver.toMap(), conflictAlgorithm: ConflictAlgorithm.rollback);
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
        name: maps[i]['name']
      );
    });
  }


  Future<Database> _init() async {
    return openDatabase(
        join(await getDatabasesPath(), Constants.dbName),
        version: Constants.dbVersion,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE ${Constants.tableName}(path TEXT PRIMARY KEY, name TEXT)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) {},
        onDowngrade: (db, oldVersion, newVersion) {}
    );
  }
}