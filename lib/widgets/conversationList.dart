import 'dart:core';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_porject/screens/chat_screen.dart';
import 'package:my_porject/resources/methods.dart';
import 'package:my_porject/screens/group/group_chat_room.dart';

class ConversationList extends StatefulWidget {
  User user;
  Map<String, dynamic> chatHistory ;
  bool isDeviceConnected;
  ConversationList({key, required this.chatHistory,required this.user, required this.isDeviceConnected});

  @override
  _ConversationListState createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {

  late Map<String, dynamic> userMap;

  final DateFormat formatter = DateFormat('Hm');

  void conversation() async {
    FirebaseFirestore _firestore =  FirebaseFirestore.instance;

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
            return ChatScreen(chatRoomId: roomId, userMap: userMap, user: widget.user,isDeviceConnected : widget.isDeviceConnected);
          })
      );
    }

  }
  void groupConversation() async {
    if(mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return GroupChatRoom(groupChatId: widget.chatHistory['uid'], groupName: widget.chatHistory['name'], user: widget.user, isDeviceConnected: widget.isDeviceConnected,);
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
                      backgroundImage: CachedNetworkImageProvider(widget.chatHistory['avatar']),
                      maxRadius: 30,
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Text(widget.chatHistory['name'] == null ?  "UserName" : widget.chatHistory['name'],style: TextStyle(fontSize: 16),),
                              Row(
                                children: [
                                  widget.chatHistory['name'].toString().length >= 25
                                      ? Text(
                                      '${widget.chatHistory['name'].toString().substring(0, 25)}...',
                                      style: TextStyle(
                                        fontWeight: widget.chatHistory['isRead'] == false ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      )
                                  )
                                      : Text(widget.chatHistory['name'], style: TextStyle(
                                    fontWeight: widget.chatHistory['isRead'] == false ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  )
                                  ),
                                  SizedBox(width: 10,),
                                  widget.chatHistory['isRead'] == false ?
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 3,
                                        )
                                    ),
                                  ) : Container(),
                                ],
                              ),
                              SizedBox(height: 6,),
                              Row(
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2.1,),
                                    child: widget.chatHistory['lastMessage'].toString().length >= 21
                                        ? Text(
                                      '${widget.chatHistory['lastMessage'].toString().substring(0, 21)}...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: widget.chatHistory['isRead'] == false ? FontWeight.bold : FontWeight.normal,
                                          color: Colors.grey.shade700,)
                                    )
                                        : Text(widget.chatHistory['lastMessage'], style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: widget.chatHistory['isRead'] == false ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.grey.shade700,)
                                    )
                    ),
                                  SizedBox(width: 10,),
                                  Text(
                                    widget.chatHistory['time'].toString().substring(11, 16),
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
                  widget.chatHistory['time'].toString().substring(0, 10),
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
