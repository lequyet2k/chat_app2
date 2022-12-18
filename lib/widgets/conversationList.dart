import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:intl/intl.dart';
import 'package:my_porject/chat_screen.dart';
import 'package:my_porject/resources/methods.dart';
import 'package:my_porject/screens/group_chat_room.dart';

class ConversationList extends StatefulWidget {
  User user;
  Map<String, dynamic> chatHistory ;
  ConversationList({super.key, required this.chatHistory,required this.user});

  @override
  _ConversationListState createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseAuth _auth = FirebaseAuth.instance;

  late Map<String, dynamic> userMap;

  final DateFormat formatter = DateFormat('Hm');

  String convertTime(Timestamp now) {
    int timestamp = now.millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String datetime = tsdate.year.toString().substring(2) + "/" + tsdate.month.toString() + "/" + tsdate.day.toString();
    return datetime;
  }
  String convertHours(Timestamp now) {
    int timestamp = now.millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String datetime = tsdate.hour.toString() + ":" + tsdate.minute.toString();
    return datetime;
  }

  void conversation() async {
    FirebaseFirestore _firestore =  FirebaseFirestore.instance;

    FirebaseAuth _auth = FirebaseAuth.instance;

    await _firestore.collection('users').where("uid", isEqualTo: widget.chatHistory['uid']).get().then((value) {
      setState(() {
        userMap = value.docs[0].data() ;
      });
    });

    String roomId = ChatRoomId().chatRoomId(widget.user.displayName,widget.chatHistory['name']);
    if(mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return ChatScreen(chatRoomId: roomId, userMap: userMap, user: widget.user,);
          })
      );
    }

  }
  void groupConversation() async {
    if(mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return GroupChatRoom(groupChatId: widget.chatHistory['uid'], groupName: widget.chatHistory['name'], user: widget.user, currentUserName: widget.user.displayName);
          })
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(widget.chatHistory['datatype'] == 'group') {
          groupConversation();
        }else {
          conversation();
        }
      },
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top :10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.chatHistory['avatar']),
                      maxRadius: 30,
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(widget.chatHistory['name'] == null ?  "UserName" : widget.chatHistory['name'],style: TextStyle(fontSize: 16),),
                              SizedBox(height: 6,),
                              Row(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2.1,),
                                    child: Text(widget.chatHistory['lastMessage'], style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,)
                                        //fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal),
                                    ),
                                  ),
                                  Text(" "),
                                  Text(
                                    convertHours(widget.chatHistory['time']),
                                    //widget.chatHistory['time'],
                                    style: TextStyle(
                                      fontSize:   12,
                                      //fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ),
                  ],
                ),
            ),
            SizedBox(width: 10,),
            Column(
              children: [
                Text(
                  convertTime(widget.chatHistory['time']),
                  //widget.chatHistory['time'],
                  style: TextStyle(
                    fontSize:   12,
                    //fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
