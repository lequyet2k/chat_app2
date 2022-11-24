// import 'dart:html';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  Map<String, dynamic> userMap ;

  late String chatRoomId ;

  late String currentUserName;

  ChatScreen({required this.chatRoomId, required this.userMap, required this.currentUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String user1Name;

  void onSendMessage() async {

    if(_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        'sendBy' : widget.currentUserName,
        'message' : _message.text,
        'type' : "text",
        'time' :  FieldValue.serverTimestamp()
      };
      _message.clear();

      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').add(messages);

    } else {
      print("Enter some text");
    }

  }

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if(xFile != null){
        imageFile = File(xFile.path as String);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {

    String fileName =   Uuid().v1();

    int status = 1 ;

    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(fileName).set({
      'sendBy' : widget.currentUserName,
      'message' : _message.text,
      'type' : "img",
      'time' :  FieldValue.serverTimestamp(),
    });

    var ref = FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask =  await ref.putFile(imageFile!).catchError((error) async {
      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(fileName).delete();
      status = 0;
    });

    if(status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(fileName).update({
        'message' : imageUrl,
      });

      print(imageUrl);
    }

  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios, color: Colors.black,),
                ),
                SizedBox(width: 2,),
                CircleAvatar(
                  backgroundImage: AssetImage("assets/images/user.png"),
                  maxRadius: 20,
                ),
                SizedBox(width: 12,),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                            widget.userMap['name'],
                          style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6,),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore.collection("users").doc(widget.userMap['uid']).snapshots(),
                          builder: (context, snapshot) {
                            if(snapshot.data != null ) {
                              return Text(
                                snapshot.data!['status'],
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13,),
                              );
                            } else {
                              return Text('null');
                            }
                          },
                        )
                      ],
                    ),
                ),
                Icon(Icons.settings, color: Colors.black54,)
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('time',descending: false).snapshots(),
              builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                if(snapshot.data!= null){
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                      return messages(size, map,context);
                    },
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
          // ListView.builder(
          //   itemCount: messages.length,
          //   shrinkWrap: true,
          //   padding: EdgeInsets.only(top: 10, bottom: 10),
          //   physics: NeverScrollableScrollPhysics(),
          //   itemBuilder: (context, index){
          //     return Container(
          //       padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
          //       child: Align(
          //         alignment: (messages[index].messageType == "receiver"?Alignment.topLeft:Alignment.topRight),
          //         child: Container(
          //           decoration: BoxDecoration(
          //             borderRadius: BorderRadius.circular(20.0),
          //             color: (messages[index].messageType == "receiver"?Colors.grey.shade200:Colors.blue[200]),
          //           ),
          //           padding: EdgeInsets.all(16),
          //           child: Text(
          //             messages[index].messageContent,
          //             style: TextStyle(fontSize: 15,),
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(right: 20, left: 20),
              height: 70,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: (){
                      getImage();
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(Icons.add, color: Colors.white,size: 20,),
                    ),
                  ),
                  SizedBox(width: 15,),
                  Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                        controller: _message,
                      ),
                  ),
                  SizedBox(width: 15,),
                  FloatingActionButton(
                    onPressed: () {
                      onSendMessage();
                      },
                    child: Icon(Icons.send, color: Colors.white,size: 18,),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return map['type'] =="text" ? Container(
      width: size.width,
      alignment: map['sendBy'] == widget.currentUserName ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue,
        ),
        child: Text(
          map['message'],
          style: TextStyle(color: Colors.white,fontSize: 17),
        ),
      ),
    ): Container(
      height: size.height / 2.5,
      width: size.width,
      padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      alignment: map['sendBy'] == widget.currentUserName
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ShowImage(imageUrl: map['message'])),
        ),
        child: Container(
          height: size.height / 2.5,
          width: size.width / 2,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          alignment: map['message'] != "" ? null : Alignment.center,
          child: map['message'] != ""? Image.network(map['message'], fit: BoxFit.cover,) : CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class ShowImage extends StatelessWidget {
  const ShowImage({ Key? key, required this.imageUrl }) :super(key :key);

  final String imageUrl ;

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}
