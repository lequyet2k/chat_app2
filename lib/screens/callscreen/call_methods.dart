import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_porject/models/call_model.dart';
import 'package:uuid/uuid.dart';

import '../../resources/methods.dart';

class CallMethods {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference callCollection = FirebaseFirestore.instance.collection('calls');

  Stream<DocumentSnapshot> callStream({required String? uid}) => callCollection.doc(uid).snapshots();

  String chatRoomId(String user1, String user2){
    if(user1[0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  String? chatRooomId;

  Future<bool> makeCall({required Call call}) async {

    String docName =   Uuid().v1();

    chatRooomId = chatRoomId(call.callerName as String, call.receiverName as String);
    await _firestore.collection('chatroom').doc(chatRooomId).collection('chats').doc(docName).set({
      "type" : "videocall",
      "sendBy" : call.callerName,
      "message" : "Videocall",
      "time" : timeForMessage(DateTime.now().toString()),
      "messageId" : docName,
    });

    await _firestore.collection('chatroom').doc(chatRooomId).set({
      'user1' : call.callerName,
      'user2' : call.receiverName,
      'lastMessage' : "Videocall",
      'type' : "videocall",
      'messageId' : docName,
      'time' : timeForMessage(DateTime.now().toString()),
    });

    await _firestore.collection('users').doc(call.callerId).collection('chatHistory').doc(call.receiverId).update({
      'lastMessage' : "Bạn đã gọi cho ${call.receiverName}",
      'type' : "videocall",
      'name' : call.receiverName,
      'time' : timeForMessage(DateTime.now().toString()),
      'uid' : call.receiverId,
      'avatar' : call.receiverPic,
    });

    await _firestore.collection('users').doc(call.receiverId).collection('chatHistory').doc(call.callerId).update({
      'lastMessage' : "${call.callerName} đã gọi cho bạn",
      'type' : "videocall",
      'name' : call.callerName,
      'time' : timeForMessage(DateTime.now().toString()),
      'uid' : call.callerId,
      'avatar' : call.callerPic,
    });

    try {
      call.hasDialled = true;
      Map<String, dynamic> hasDialledMap = call.toMap(call) ;
      call.hasDialled = false;
      Map<String, dynamic> hasNotDialledMap =  call.toMap(call);
      await callCollection.doc(call.callerId).set(hasDialledMap);
      await callCollection.doc(call.receiverId).set(hasNotDialledMap);
      return true;
    } catch(e){
      print(e);
      return false;
    }

  }


  Future<bool> endCall({required Call call}) async {
    chatRooomId = chatRoomId(call.callerName as String, call.receiverName as String);
    String? messageId;
    String? time;
    await _firestore.collection('chatroom').doc(chatRooomId).get().then((value){
      messageId = value.data()!['messageId'] ;
      time = value.data()!['time'];
    });
    // await _firestore.collection('chatroom').doc(chatRooomId).collection('chats').doc(messageId).update({
    //   'timeSpend' : DateTime.now().second - (time!.toDate().second),
    // });
    try{
      await callCollection.doc(call.callerId).delete();
      await callCollection.doc(call.receiverId).delete();
      return true;
    } catch(e) {
      return false;
    }
  }

}


