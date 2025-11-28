import 'dart:core';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:my_porject/screens/chat_screen.dart';
import 'package:my_porject/resources/methods.dart';
import 'package:my_porject/screens/group/group_chat_room.dart';

// ignore: must_be_immutable
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

  bool? isDeviceConnected;

  void conversation() async {
    FirebaseFirestore _firestore =  FirebaseFirestore.instance;

    await _firestore.collection('users').where("uid", isEqualTo: widget.chatHistory['uid']).get().then((value) {
      setState(() {
        userMap = value.docs[0].data() ;
      });
    });
    widget.isDeviceConnected = await InternetConnection().hasInternetAccess;

    String roomId = ChatRoomId().chatRoomId(widget.user.displayName,widget.chatHistory['name']);

    if(mounted) {
      setState(() {
        isDeviceConnected = widget.isDeviceConnected;
      });
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return ChatScreen(chatRoomId: roomId, userMap: userMap, user: widget.user,isDeviceConnected : isDeviceConnected!);
          })
      );
    }

  }
  void groupConversation() async {
    widget.isDeviceConnected = await InternetConnection().hasInternetAccess;
    if(mounted) {
      setState(() {
        isDeviceConnected = widget.isDeviceConnected;
      });
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return GroupChatRoom(groupChatId: widget.chatHistory['uid'], groupName: widget.chatHistory['name'], user: widget.user, isDeviceConnected: isDeviceConnected!,);
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
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.chatHistory['isRead'] == false 
                        ? Colors.blue 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(widget.chatHistory['avatar']),
                  radius: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.chatHistory['name'].toString().length >= 25
                                ? '${widget.chatHistory['name'].toString().substring(0, 25)}...'
                                : widget.chatHistory['name'],
                            style: TextStyle(
                              fontWeight: widget.chatHistory['isRead'] == false 
                                  ? FontWeight.w700 
                                  : FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.chatHistory['isRead'] == false) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.chatHistory['lastMessage'].toString().length >= 30
                                ? '${widget.chatHistory['lastMessage'].toString().substring(0, 30)}...'
                                : widget.chatHistory['lastMessage'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: widget.chatHistory['isRead'] == false 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                              color: widget.chatHistory['isRead'] == false 
                                  ? Colors.grey[700]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.chatHistory['time'].toString().substring(11, 16)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: widget.chatHistory['isRead'] == false 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
