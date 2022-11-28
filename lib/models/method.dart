import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Conversation extends StatefulWidget {

  String chatRoomId;

  Conversation({Key? key, required this.chatRoomId}) ;

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseAuth _auth = FirebaseAuth.instance;

//   void test() async {
//
//     Map<String, dynamic> chatRoomInfo = {
//       'user1' : ,
//       'user2' : ,
//       'lastMessage' : ,
//       'type' : ,
//     };
//
//     String user1Name ;
//     String user2Name ;
//
//     await _firestore.collection('users').where("email", isEqualTo: _auth.currentUser?.email).get().then((value) {
//       setState(() {
//         user1Name = value.docs[0].get("name");
//       });
//     });
//
//
//     await _firestore.collection('chatroom').where("user1", isEqualTo: user1Name ).get().then((value){
//       user2Name = value.docs[0].data()['user2'];
//       _firestore.collection('users').where('email', isEqualTo: )
//     });
//
//     await _firestore.collection('chatroom').where("user2", isEqualTo: _auth.currentUser!.email).get().then((value){
//       user2Name = value.docs[0].data()['user1'];
//     });
//
// }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
