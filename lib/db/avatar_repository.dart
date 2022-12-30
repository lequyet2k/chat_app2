import 'package:my_porject/db/sqlite_methods.dart';

import '../models/avatar_model.dart';

class AvatarRepository {
  static var dbObject;

  static init({required String dbName}) {
    dbObject =  SqliteMethods();
    dbObject.openDb(dbName);
    dbObject.init();
  }

  static saveAvatar(Avatar avatar) => dbObject.saveAvatar(avatar);

  // static deleteLogs(int logId) => dbObject.deleteLogs(logId);

  // static getLogs() => dbObject.getLogs();

  // static close() => dbObject.close();
}