import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomId {
  String chatRoomId(String? user1, String user2){
    if(user1![0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }
}

Future<String?> getCurrentUserName() async {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserName;
  await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((value) {
    Map<String, dynamic>? map = value.data();
    currentUserName = map!['name'];
  });
  return currentUserName;
}
