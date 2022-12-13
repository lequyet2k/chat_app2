import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group_info.dart';

class GroupChatRoom extends StatefulWidget {
  User user;
  final String groupChatId,groupName;
  final String? currentUserName;

  GroupChatRoom({Key? key, required this.groupChatId, required this.groupName,required this.user, required this.currentUserName}) : super(key: key);

  @override
  State<GroupChatRoom> createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final TextEditingController _message = TextEditingController();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth _auth = FirebaseAuth.instance;

  List memberList = [];

  void onSendMessage() async {
    String? avatarUrl;

    await _firestore.collection('users').doc(widget.user.uid).get().then((value) {
      avatarUrl = value.data()!['avatar'].toString();
    });
    String message;
    message = _message.text;
    if(_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy" : widget.currentUserName,
        "message" : _message.text,
        "type" : "text",
        "time" : DateTime.now(),
        'avatar' : avatarUrl,
      };

      _message.clear();

      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').add(chatData);
      await _firestore.collection('users').doc(widget.user.uid).collection('chatHistory').doc(widget.groupChatId).update({
        'lastMessage' : "Bạn: $message",
        'type' : "text",
        'time' : DateTime.now(),
      });
      await _firestore.collection('groups').doc(widget.groupChatId).get().then((value) {
        memberList = value.data()!['members'];
        print(memberList);
      });
      for(int i = 0 ; i < memberList.length ; i++) {
        await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
          'lastMessage' : "${widget.currentUserName}: $message",
          'type' : "text",
          'time' : DateTime.now(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.groupName),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroupInfo(groupName: widget.groupName, groupId: widget.groupChatId, currentUserName: widget.currentUserName,user: widget.user, memberListt: memberList,)),
              );
            },
            icon: Icon(Icons.more_vert),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
                color: Colors.grey.shade500,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('groups').doc(widget.groupChatId).collection('chats').orderBy('time',descending: false).snapshots(),
                builder: (context, snapshot){
                  if(snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index){
                        Map<String, dynamic> chatMap = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                        return messageTitle(size, chatMap);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              )
            ),
          ),
          Container(
            height: size.height / 15,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(bottom: 10,top: 10),
              color: Colors.black,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                    },
                    icon: Icon(Icons.image_outlined, color: Colors.blueAccent,),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.location_on, color: Colors.blueAccent,),
                  ),
                  IconButton(
                    onPressed: (){},
                    icon: Icon(Icons.keyboard_voice, color: Colors.blueAccent,),
                  ),
                  // SizedBox(width: 15,),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade700,
                        hintText: "Aa",
                        hintStyle: TextStyle(color: Colors.white30),
                        contentPadding: EdgeInsets.all(8.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      controller: _message,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onSendMessage();
                    },
                    icon: Icon(Icons.send, color: Colors.blueAccent,),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget messageTitle(Size size , Map<String, dynamic> chatMap) {
    return Builder(builder: (context) {
      if(chatMap['type'] == 'text') {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: 2,),
            chatMap['sendBy'] != widget.user.displayName ?
            Container(
              margin: EdgeInsets.only(bottom: 5),
              height: size.width / 13 ,
              width: size.width / 13 ,
              child: CircleAvatar(
                backgroundImage: NetworkImage(chatMap['avatar']),
                maxRadius: 30,
              ),
            ): Container(
            ),
            Column(
              children: [
                chatMap['sendBy'] != widget.user.displayName ?
                Container(
                  padding: EdgeInsets.only(left: 8),
                  width:  size.width * 0.7,
                  alignment:  Alignment.centerLeft,
                  child: Text(
                    chatMap['sendBy'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ): Container(),
                Container(
                  width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
                  alignment: chatMap['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints( maxWidth: size.width / 1.5),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black,
                    ),
                    child: Column(
                      children: [
                        Text(
                          chatMap['message'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
      else if(chatMap['type'] == 'img') {
        return Container(
          width: size.width,
          alignment: chatMap['sendBy'] ==  widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.blue,
            ),
            child: Text(
              chatMap['message'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }else if(chatMap['type'] == 'notify'){
        return Container(
          width: size.width,
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black38,
            ),
            child: Text(
              chatMap['message'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }else {
        return SizedBox();
      }
    });
  }
}
