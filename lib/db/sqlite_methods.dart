import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/log_model.dart';

class SqliteMethods {
  Database? _db;

  String databaseName = 'logDB' ;

  String tableName = 'call_logs';

  String id = 'log_id';
  String callerName = 'caller_name';
  String callerPic = 'caller_pic';
  String receiverName = 'receiver_name';
  String receiverPic = 'receiver_pic';
  String callStatus = 'call_status';
  String timeStamp = 'time_stamp';

  Future<Database?> get db async {
    if(_db != null) {
      return _db;
    }
    print('db was null, now awaiting it');
    _db = await init();
    return _db;
  }

  @override
  openDb(dbName) => (databaseName = dbName);

  @override
  init() async {
    Directory dir = await getApplicationDocumentsDirectory();

    String path = join(dir.path, databaseName);
    
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async {
    String createTableQuery =
        "CREATE TABLE $tableName ($id INTERGER PRIMARY KEY, $callerName TEXT, $callerPic TEXT , $receiverName TEXT, $receiverPic TEXT, $callStatus TEXT, $timeStamp TEXT";
    
    await db.execute(createTableQuery);
    print('table created');
  }

  @override
  addLogs(Log log) async {
    var dbClient = await db;

    await dbClient?.insert(tableName, log.toMap(log));
  }

  @override
  deleteLog(int logId) async {
    var dbClient = await db;
    return await dbClient?.delete(tableName, where : '$id = ?' , whereArgs: [logId]);
  }

  updateLogs(Log log) async {
    var dbClient = await db;
    
    await dbClient?.update(
        tableName,
        log.toMap(log),
      where: '$id = ?',
      whereArgs: [log.logId],
    );
  }

  @override
  Future<List<Log>?> getLogs() async {
    try{
      var dbClient = await db;

      // List<Map<String, Object?>>? maps = await dbClient?.rawQuery('SELECT * FROM $tableName');
      List<Map<String, Object?>>? maps = await dbClient?.query(
          tableName,
        columns: [
          id,
          callerName,
          callerPic,
          receiverName,
          receiverPic,
          callStatus,
          timeStamp,
        ]
      );
      
      List<Log> logList = [];
      
      if(maps != null) {
        for(Map map in maps) {
          logList.add(Log.fromMap(map));
        }
      }

      return logList;
    }catch(e){
      print(e);
      return null;
    }
  }

  @override
  close() async {
    var dbClient = await db;
    dbClient?.close();
  }
}