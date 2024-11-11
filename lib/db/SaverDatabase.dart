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

  Future<void> insertSaver(Saver saver) async {
    final db = await database;

    final saverMap = {
      'path': null,
      'name': saver.name,
      'color': saver.color,
      'count': saver.count,
      'photoName': saver.photoName,
      'suffixType': saver.suffixType
    };
    // insert saver to saver table
    db.insert(Constants.saverTableName, saverMap,
        conflictAlgorithm: ConflictAlgorithm.rollback);

    // insert paths to path table
    final saverName = saver.name;
    final pathList = saver.paths;
    for (String path in pathList) {
      db.insert(
          Constants.pathTableName,
          {
            "saver_name": saverName,
            "path": path,
          },
          conflictAlgorithm: ConflictAlgorithm.rollback);
    }
    return;
  }

  Future<void> deleteSaver(Saver saver) async {
    final db = await database;

    db.delete(Constants.saverTableName,
        where: 'name = ?', whereArgs: [saver.name]);

    db.delete(Constants.pathTableName,
        where: 'saver_name = ?', whereArgs: [saver.name]);
  }

  Future<List<Saver>> getAllSavers() async {
    final db = await database;
    List<Saver> resultList = [];

    final List<Map<String, dynamic>> savers =
        await db.query(Constants.saverTableName);

    for (Map<String, dynamic> saverMap in savers) {
      String saverName = saverMap['name'];
      int? saverColor = saverMap['color'];
      int count = saverMap['count'];
      String? photoName = saverMap['photoName'];
      int suffixType = saverMap['suffixType'];

      List<String> pathList = [];
      List<Map<String, dynamic>> paths = await db.query(Constants.pathTableName,
          where: 'saver_name = ?', whereArgs: [saverName]);
      for (Map<String, dynamic> pathMap in paths) {
        pathList.add(pathMap['path']);
      }

      resultList.add(Saver(
          paths: pathList,
          name: saverName,
          color: saverColor,
          count: count,
          photoName: photoName,
          suffixType: suffixType));
    }

    return resultList;
  }

  Future<Database> _init() async {
    return openDatabase(
      join(await getDatabasesPath(), Constants.dbName),
      version: Constants.dbVersion,
      onCreate: (db, version) {
        db.execute(
          '''
          CREATE TABLE IF NOT EXISTS ${Constants.saverTableName}(
            path TEXT PRIMARY KEY,
            name TEXT,
            color INTEGER DEFAULT NULL,
            count INTEGER,
            photoName TEXT DEFAULT NULL,
            suffixType INTEGER
          )
          ''',
        );

        db.execute('''
        CREATE TABLE IF NOT EXISTS ${Constants.pathTableName}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          saver_name TEXT,
          path TEXT,
          FOREIGN KEY(saver_name) REFERENCES ${Constants.saverTableName}(name)
        )
      ''');

        return;
      },
      onUpgrade: _onUpgrade,
      onDowngrade: (db, oldVersion, newVersion) {},
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1) {
      await _1_2(db);
      await _2_3(db);
    } else if (oldVersion == 2) {
      await _2_3(db);
    }
  }

  Future<void> _1_2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tmp_table(
        path TEXT,
        name TEXT PRIMARY KEY,
        color INTEGER DEFAULT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO tmp_table (path, name)
      SELECT path, name FROM ${Constants.saverTableName}
    ''');

    await db.execute('DROP TABLE IF EXISTS ${Constants.saverTableName}');

    await db
        .execute('ALTER TABLE tmp_table RENAME TO ${Constants.saverTableName}');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Constants.pathTableName}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          saver_name TEXT,
          path TEXT,
          FOREIGN KEY(saver_name) REFERENCES ${Constants.saverTableName}(name)
        )
      ''');

    final List<Map<String, dynamic>> existingData =
        await db.query(Constants.saverTableName);
    for (var row in existingData) {
      await db.insert(
        'saver_paths',
        {'saver_name': row['name'], 'path': row['path']},
      );
    }
  }

  Future<void> _2_3(Database db) async {
    await db.execute('''
        ALTER TABLE ${Constants.saverTableName} ADD COLUMN count INTEGER DEFAULT 0
      ''');

    await db.execute('''
        ALTER TABLE ${Constants.saverTableName} ADD COLUMN photoName TEXT DEFAULT NULL
      ''');

    await db.execute('''
        ALTER TABLE ${Constants.saverTableName} ADD COLUMN suffixType INTEGER DEFAULT 0
      ''');
  }
}
