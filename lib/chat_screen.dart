import 'dart:io';
import 'package:my_porject/screens/callscreen/call_utils.dart';
import 'package:my_porject/screens/callscreen/pickup/pickup_layout.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:my_porject/models/user_model.dart';

class ChatScreen extends StatefulWidget {
  Map<String, dynamic> userMap ;

  late String chatRoomId ;

  late String currentUserName;

  ChatScreen({super.key, required this.chatRoomId, required this.userMap, required this.currentUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String user1Name ;

  late String email = widget.userMap['email'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToIndex());
    getUserInfo();
  }

  late Userr receiver;
  late Userr sender;

  void getUserInfo() async {

    receiver = Userr(
      uid: widget.userMap['uid'],
      name: widget.userMap['name'],
      avatar: widget.userMap['avatar'],
      email: widget.userMap['email'],
      status: widget.userMap['status'],
    );
    Map<String, dynamic> currentUser;
    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((value) {
        Map<String, dynamic>? map = value.data();
        sender = Userr(
          uid: map!['uid'],
          name: map['name'],
          email: map['email'],
          avatar: map['avatar'],
          status: map['status'],
        );
    });
  }

  void onSendMessage() async {

    String message;
    message = _message.text;
    setState(() {
      _message.clear();
    });
    if(message.isNotEmpty) {
      Map<String, dynamic> messages = {
        'sendBy' : widget.currentUserName,
        'message' : message,
        'type' : "text",
        'time' :  DateTime.now(),
      };
      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').add(messages);
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'user1' : widget.currentUserName,
        'user2' : widget.userMap['name'],
        'lastMessage' : message,
        'type' : "text",
      });
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).set({
        'lastMessage' : "Bạn: ${message}",
        'type' : "text",
        'name' : widget.userMap['name'],
        'time' : DateTime.now(),
        'uid' : widget.userMap['uid'],
        'avatar' : widget.userMap['avatar'],
        'status' : widget.userMap['status'],
      });
      String? currentUserAvatar;
      String? status;
      await _firestore.collection("users").where("email" , isEqualTo: _auth.currentUser!.email).get().then((value) {
        currentUserAvatar = value.docs[0]['avatar'];
        status = value.docs[0]['status'];
      });
      await _firestore.collection('users').doc(widget.userMap['uid']).collection('chatHistory').doc(_auth.currentUser!.uid).set({
        'lastMessage' : message,
        'type' : "text",
        'name' : widget.currentUserName,
        'time' : DateTime.now(),
        'uid' : _auth.currentUser!.uid,
        'avatar' : currentUserAvatar,
        'status' : status,
      });
    } else {
      print("Enter some text");
    }
    scrollToIndex();
  }

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if(xFile != null){
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
    scrollToIndex();
  }

  Future uploadImage() async {

    String fileName =   Uuid().v1();

    int status = 1 ;

    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(fileName).set({
      'sendBy' : widget.currentUserName,
      'message' : _message.text,
      'type' : "img",
      'time' :  DateTime.now(),
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
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'user1' : widget.currentUserName,
        'user2' : widget.userMap['name'],
        'lastMessage' : "Bạn đã gửi 1 ảnh",
        'type' : "img",
        'uid' : widget.userMap['uid'],
      });
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).set({
        'lastMessage' : "Bạn đã gửi 1 ảnh",
        'type' : "img",
        'name' : widget.userMap['name'],
        'time' : DateTime.now(),
        'uid' : widget.userMap['uid'],
        'avatar' : widget.userMap['avatar'],
        'status' : widget.userMap['status'],
      });
      String? currentUserAvatar;
      String? status;
      await _firestore.collection("users").where("email" , isEqualTo: _auth.currentUser!.email).get().then((value) {
        currentUserAvatar = value.docs[0]['avatar'];
        status =  value.docs[0]['status'];
      });
      await _firestore.collection('users').doc(widget.userMap['uid']).collection('chatHistory').doc(_auth.currentUser!.uid).set({
        'lastMessage' : "${widget.currentUserName} đã gửi 1 ảnh",
        'type' : "img",
        'name' : widget.currentUserName,
        'time' : DateTime.now(),
        'uid' : _auth.currentUser!.uid,
        'avatar' : currentUserAvatar,
        'status' : status,
      });
    }
  }
  final itemScrollController = ItemScrollController();
  late int index;
  void scrollToIndex() async {
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').get().then((value){
      //index = value.size - 1 ;
      itemScrollController.jumpTo(index: value.size);
    });
    //itemScrollController.jumpTo(index: index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PickUpLayout(
      scaffold: Scaffold(
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
                    backgroundImage: NetworkImage(widget.userMap['avatar']),
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
                  IconButton(
                      onPressed: () async =>  CallUtils.dial(
                        from: sender,
                        to: receiver,
                        context: context,
                      ),
                      icon: Icon(Icons.video_call),
                  ),
                  Icon(Icons.settings, color: Colors.black54,)
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('time',descending: false).snapshots(),
                  builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                    if(snapshot.data!= null){
                      return ScrollablePositionedList.builder(
                        itemCount: snapshot.data?.docs.length as int,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                          return messages(size, map,context);
                        },
                        itemScrollController: itemScrollController,
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
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
      ),
    );
  }
  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    if(map['type'] == "text") {
      return Container(
        width: size.width,
        alignment: map['sendBy'] == widget.currentUserName ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints( maxWidth: size.width / 1.5),
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
      );
    } else if (map['type'] == "img") {
      return Container(
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
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: map['message'] != "" ? null : Alignment.center,
            child: map['message'] != ""? Image.network(map['message'], fit: BoxFit.cover,) : CircularProgressIndicator(),
          ),
        ),
      );
    } else {
      return Container(
        width: size.width,
        alignment: map['sendBy'] == widget.currentUserName ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: size.width / 3,
          // constraints: BoxConstraints( maxWidth: size.width / 1.5),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey,
          ),
          child: Row(
            children: [
              Icon(
                  Icons.call_sharp,
              ),
              SizedBox(width: 5,),
              Column(
                children: [
                  Text(
                      "Video Call",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
          // int.parse(map['timeSpend'].toString()) < 60 ?
                    map['timeSpend'].toString() + "s" ,
                // : (map['timeSpend'] / 60).toString() + "p "+ (map['timeSpend'] % 60).toString() + "s",
                    style: TextStyle(
                      fontSize: 13,
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
