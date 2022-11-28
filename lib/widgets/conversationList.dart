import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/models/chatUsersModel.dart';
import 'package:my_porject/chat_screen.dart';
import 'package:my_porject/chathome_screen.dart';

class ConversationList extends StatefulWidget {
  String name;
  String messageText;
  String imageUrl;
  String time;
  bool isMessageRead;
  ConversationList({required this.name,required this.messageText,required this.imageUrl,required this.time,required this.isMessageRead});

  @override
  _ConversationListState createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseAuth _auth = FirebaseAuth.instance;

  late String chatRoomId;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context){
        //     return ChatScreen();
        //   })
        // );
      },
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top :10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: AssetImage(widget.imageUrl),
                      maxRadius: 30,
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(widget.name,style: TextStyle(fontSize: 16),),
                              SizedBox(height: 6,),
                              Text(widget.messageText, style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                    )
                  ],
                ),
            ),
            Text(
              widget.time,
              style: TextStyle(
                fontSize:   12,
                fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
