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

  User user;

  ChatScreen({super.key, required this.chatRoomId, required this.userMap, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String email = widget.userMap['email'];

  bool isLoading = false;

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
        'sendBy' : widget.user.displayName,
        'message' : message,
        'type' : "text",
        'time' :  DateTime.now(),
      };
      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').add(messages);
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'user1' : widget.user.displayName,
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
        'name' : widget.user.displayName,
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
      'sendBy' : widget.user.displayName,
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
        'user1' : widget.user.displayName,
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
        'lastMessage' : "${widget.user.displayName} đã gửi 1 ảnh",
        'type' : "img",
        'name' : widget.user.displayName,
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
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').get().then((value) {
      print(value.docs.length);
      itemScrollController.jumpTo(index: value.docs.length - 1);
    });
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
        body: isLoading ? Container(
          height: size.height ,
          width: size.width ,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ) : Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Colors.grey.shade500,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('time',descending: false).snapshots(),
                  builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                    if(snapshot.data!= null){
                      return ScrollablePositionedList.builder(
                        itemCount: snapshot.data?.docs.length as int,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                          return messages(size, map,widget.userMap,context);
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
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(bottom: 10,top: 10),
                height: size.height / 16,
                width: double.infinity,
                color: Colors.black,
                child: Row(
                  children: <Widget>[
                    IconButton(
                        onPressed: () {
                          getImage();
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
      ),
    );
  }
  Widget messages(Size size, Map<String, dynamic> map,Map<String, dynamic> userMap, BuildContext context) {
    if(map['type'] == "text") {
      return Row(
        children: [
          SizedBox(width: 2,),
          map['sendBy'] != widget.user.displayName ?
          Container(
            height: size.width / 13 ,
            width: size.width / 13 ,
            child: CircleAvatar(
              backgroundImage: NetworkImage(userMap['avatar']),
              maxRadius: 30,
            ),
          ): Container(
          ),
          Container(
            width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
            alignment: map['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints( maxWidth: size.width / 1.5),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black,
              ),
              child: Text(
                map['message'],
                style: TextStyle(color: Colors.white,fontSize: 17),
              ),
            ),
          ),
        ],
      );
    } else if (map['type'] == "img") {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 2,),
          map['sendBy'] != widget.user.displayName ?
          Container(
            margin: EdgeInsets.only(bottom: 8),
            height: size.width / 13 ,
            width: size.width / 13 ,
            child: CircleAvatar(
              backgroundImage: NetworkImage(userMap['avatar']),
              maxRadius: 30,
            ),
          ): Container(
          ),
          Container(
            height: size.height / 2.5,
            width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
            padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
            alignment: map['sendBy'] == widget.user.displayName
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
                child: map['message'] != ""? ClipRRect(borderRadius: BorderRadius.circular(18.0),child: Image.network(map['message'], fit: BoxFit.cover,)) : CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 2,),
          map['sendBy'] != widget.user.displayName ?
          Container(
            margin: EdgeInsets.only(bottom: 5),
            height: size.width / 13 ,
            width: size.width / 13 ,
            child: CircleAvatar(
              backgroundImage: NetworkImage(userMap['avatar']),
              maxRadius: 30,
            ),
          ): Container(
          ),
          Container(
            width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
            alignment: map['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: size.width / 3,
              // constraints: BoxConstraints( maxWidth: size.width / 1.5),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade900,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.grey,
                    ),
                    child: Icon(
                        Icons.call_sharp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(width: 5,),
                  Column(
                    children: [
                      Text(
                          "Video Call",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
              // int.parse(map['timeSpend'].toString()) < 60 ?
                        map['timeSpend'].toString() + "s" ,
                    // : (map['timeSpend'] / 60).toString() + "p "+ (map['timeSpend'] % 60).toString() + "s",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
