import 'dart:io';
import 'package:my_porject/models/avatar_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteMethods {
  Database? _db;

  String databaseName = ' ' ;

  String tableName = 'chatHistory';
  String uid = 'uid';
  String avatar = 'avatar';
  String datatype = 'datatype';

  Future<Database?> get db async {
    if(_db != null) {
      return _db;
    }
    print('db was null, now awaiting it.......');
    _db = await init();
    return _db;
  }

  openDb(dbName) => (databaseName = dbName);

  init() async {

    Directory dir = await getApplicationDocumentsDirectory();

    String path = join(dir.path, databaseName);

    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async {
    String createTableQuery =
        "CREATE TABLE $tableName ($uid TEXT PRIMARY KEY,  $avatar BLOB, $datatype TEXT";

    await db.execute(createTableQuery);
    print('table created success');
  }

  void saveAvatar(Avatar avatar) async {
    var dbClient = await db;
    await dbClient?.insert(tableName, avatar.toMap(avatar));
  }
}