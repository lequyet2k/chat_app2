
import 'dart:typed_data';

class Avatar {
  String? uid;
  String? datatype;
  Uint8List? avatar;

  Avatar(
      {
        required this.uid,
        required this.datatype,
        required this.avatar,
      }
      );

  Avatar.fromMap(Map avatarMap) {
    uid = avatarMap['uid'];
    datatype = avatarMap['datatype'];
    avatar = avatarMap['avatar'];
  }

  Map<String, dynamic> toMap(Avatar avatar)  {
    Map<String, dynamic> avatarMap = Map();
    avatarMap['uid'] = avatar.uid;
    avatarMap['datatype']= avatar.datatype;
    avatarMap['avatar'] = avatar.avatar ;
    return avatarMap;
  }

}
