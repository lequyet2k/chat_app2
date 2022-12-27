import 'package:flutter/cupertino.dart';
import 'package:my_porject/db/sqlite_methods.dart';

import '../models/log_model.dart';

class LogRepository {
  static var dbObject;

  static init({required String dbName}) {
    dbObject =  SqliteMethods();
    dbObject.openDb(dbName);
    dbObject.init();
  }

  static addLogs(Log log) => dbObject.addLogs(log);

  static deleteLogs(int logId) => dbObject.deleteLogs(logId);

  static getLogs() => dbObject.getLogs();

  static close() => dbObject.close();
}
