import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/screens/group/group_info.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';

import '../chat_screen.dart';
import '../../resources/methods.dart';

class GroupChatRoom extends StatefulWidget {
  User user;
  bool isDeviceConnected;
  final String groupChatId,groupName;

  GroupChatRoom({Key? key, required this.groupChatId, required this.groupName,required this.user, required this.isDeviceConnected }) : super(key: key);

  @override
  State<GroupChatRoom> createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final TextEditingController _message = TextEditingController();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth _auth = FirebaseAuth.instance;

  List memberList = [];
  String? avatarUrl;

  @override
  void initState() {
    getConnectivity();
    getMemberList();
    getCurrentUserAvatar();
    updateIsReadMessage();
    // WidgetsBinding.instance.addPostFrameCallback((_) => scrollToIndex());
    super.initState();
    focusNode.addListener(() {
      if(focusNode.hasFocus) {
        setState(() {
          showEmoji = false;
        });
      }
    });
  }

  @override
  void dispose() {
    updateIsReadMessage();
    super.dispose();
  }


  late StreamSubscription subscription;

  getConnectivity() async {
    return subscription = Connectivity().onConnectivityChanged.listen(
            (ConnectivityResult result) async {
          widget.isDeviceConnected = await InternetConnectionChecker().hasConnection;
          if(mounted){
            setState(() {

            });
          }
        }
    );
  }

  updateIsReadMessage() async{
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.groupChatId).update({
      'isRead' : true,
    });
  }

  void getCurrentUserAvatar() async {
    await _firestore.collection('users').doc(widget.user.uid).get().then((value) {
      avatarUrl = value.data()!['avatar'].toString();
    });
  }

  void onSendMessage() async {
    String message;
    message = _message.text;
    if(_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy" : widget.user.displayName,
        "message" : _message.text,
        "type" : "text",
        "time" : timeForMessage(DateTime.now().toString()),
        'avatar' : avatarUrl,
        'timeStamp' : DateTime.now(),
      };

      _message.clear();

      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').add(chatData);
      for(int i = 0 ; i < memberList.length ; i++) {
        await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
          'lastMessage' : "${widget.user.displayName}: $message",
          'type' : "text",
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
          'isRead' : false,
        });
      }
    }
  }

  void getMemberList() async {
    await _firestore.collection('groups').doc(widget.groupChatId).get().then((value) {
      memberList = value.data()!['members'];
    });
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
    // scrollToIndex();
  }
  Future uploadImage() async {

    String fileName =   Uuid().v1();

    int status = 1 ;

    await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(fileName).set({
      'sendBy' : widget.user.displayName,
      'message' : _message.text,
      'type' : "img",
      'time' :  timeForMessage(DateTime.now().toString()),
      'avatar' : avatarUrl,
      'timeStamp' : DateTime.now(),
    });

    var ref = FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask =  await ref.putFile(imageFile!).catchError((error) async {
      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(fileName).delete();
      status = 0;
    });


    if(status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(fileName).update({
        'message' : imageUrl,
      });
      for(int i = 0 ; i < memberList.length ; i++) {
        await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
          'lastMessage' : "${widget.user.displayName} đã gửi một ảnh",
          'type' : "img",
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
          'isRead' : false,
        });
      }
    }
  }
  final itemScrollController = ItemScrollController();
  // void scrollToIndex() async {
  //   await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').get().then((value) {
  //     itemScrollController.jumpTo(index: value.docs.length - 1);
  //   });
  // }
  late String lat;
  late String long;

  int limit = 20;
  Future<void> abc() async {
    setState(() {
      limit += 20;
    });
  }

  FocusNode focusNode = FocusNode();

  bool showEmoji = false;
  Widget showEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        config: Config(
          columns: 7,
        ),
        onEmojiSelected: (emoji, category) {
          _message.text = _message.text + category.emoji;
          print(emoji);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HomeScreen(user: widget.user) )
                    );
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent,),
                ),
                const SizedBox(width: 2,),
                const CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider('https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98'),
                  maxRadius: 20,
                ),
                const SizedBox(width: 12,),
                widget.groupName.length >= 25
                    ? Text(
                    '${widget.groupName.substring(0, 25)}...',
                    style: const TextStyle(
                        fontSize: 17,fontWeight: FontWeight.w600)
                )
                    : Text(widget.groupName, style: const TextStyle(
                    fontSize: 17,fontWeight: FontWeight.w600)
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupInfo(groupName: widget.groupName, groupId: widget.groupChatId, user: widget.user, memberListt: memberList, isDeviceConnected: widget.isDeviceConnected,))
                    );
                  },
                  icon: const Icon(Icons.more_vert,color: Colors.blueAccent,),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return abc();
        },
        child: Column(
          children: <Widget>[
            widget.isDeviceConnected == false
                ? Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 30,
              // color: Colors.red,
              child: const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ) : Container(),
            Expanded(
              child: Container(
                  color: Colors.white24,
                width: size.width,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('groups').doc(widget.groupChatId).collection('chats').orderBy('timeStamp',descending: false).limit(limit).snapshots(),
                  builder: (context, snapshot){
                    if(snapshot.hasData) {
                      return GroupedListView<QueryDocumentSnapshot<Object?>, String>(
                        elements: snapshot.data?.docs as List<QueryDocumentSnapshot<Object?>> ,
                        shrinkWrap: true,
                        groupBy: (element) => element['time'],
                        groupSeparatorBuilder:  (String groupByValue) => Container(
                          alignment: Alignment.center,
                          height: 30,
                          child: Text(
                            "${groupByValue.substring(11,16)}, ${groupByValue.substring(0,10)}",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        // itemCount: snapshot.data?.docs.length as int ,
                        indexedItemBuilder: (context, element, index) {
                          // Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                          Map<String, dynamic> map = element.data() as Map<String, dynamic>;
                          return messageTitle(size, map, index, snapshot.data!.docs.length);
                        },
                        // controller: itemScrollController,
                      );

                    } else {
                      return Container();
                    }
                  },
                )
              ),
            ),
            Column(
              children: [
                Container(
                  height: size.height / 16,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    // padding: EdgeInsets.only(bottom: 10,top: 10),
                    color: Colors.white70,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            getImage();
                          },
                          icon: Icon(Icons.image_outlined, color: Colors.blueAccent,),
                        ),
                        IconButton(
                          onPressed: () {
                            if(widget.isDeviceConnected == false) {
                              showDialogInternetCheck();
                            } else {
                              checkUserisLocationed();
                            }
                          },
                          icon: Icon(Icons.location_on, color: Colors.blueAccent,),
                        ),
                        // SizedBox(width: 15,),
                        Expanded(
                          child: SizedBox(
                            height: size.height / 20.8,
                            child: TextField(
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade300,
                                // hintText: "Aa",
                                // hintStyle: TextStyle(color: Colors.white30),
                                prefixIcon: const Icon(Icons.abc),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      focusNode.unfocus();
                                      focusNode.canRequestFocus = false;
                                      showEmoji = !showEmoji;
                                    });
                                  },
                                  icon: const Icon(Icons.emoji_emotions,color: Colors.blueAccent,),
                                ) ,
                                // contentPadding: EdgeInsets.all(8.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              controller: _message,
                            ),
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
                ),
              ],
            ),
            showEmoji ? showEmojiPicker() : Container(),
          ],
        ),
      ),
    );
  }

  Widget messageTitle(Size size , Map<String, dynamic> chatMap,int index,int length) {
    return Builder(builder: (context) {
      if(chatMap['status'] == 'removed'){
        return Row(
          children: [
            SizedBox(width: 2,),
            chatMap['sendBy'] != widget.user.displayName ?
            Container(
              height: size.width / 13 ,
              width: size.width / 13 ,
              child: CircleAvatar(
                backgroundImage: NetworkImage(chatMap['avatar']),
                maxRadius: 30,
              ),
            ): Container(
            ),
            GestureDetector(
              onLongPress: (){},
              child: Container(
                width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
                alignment: chatMap['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade200,
                  ),
                  child: Text(
                    chatMap['message'],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
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
                  GestureDetector(
                    onLongPress: (){
                      if(chatMap['sendBy'] == widget.user.displayName){
                        changeMessage(index, length, chatMap['message'], chatMap['type']);
                      }
                    },
                    child: Container(
                      width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
                      alignment: chatMap['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints( maxWidth: size.width / 1.5),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.blueAccent,
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
                  ),
                ],
              ),
            ],
          );
        }
        else if(chatMap['type'] == 'img') {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 2,),
              chatMap['sendBy'] != widget.user.displayName ?
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: size.width / 13 ,
                width: size.width / 13 ,
                child: CircleAvatar(
                  backgroundImage: NetworkImage(chatMap['avatar']),
                  maxRadius: 30,
                ),
              ): Container(
              ),
              GestureDetector(
                onLongPress: (){
                  if(chatMap['sendBy'] == widget.user.displayName){
                    changeMessage(index, length, chatMap['message'], chatMap['type']);
                  }
                },
                child: Container(
                  height: size.height / 2.5,
                  width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                  padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                  alignment: chatMap['sendBy'] == widget.user.displayName
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => ShowImage(imageUrl: chatMap['message'])),
                    ),
                    child: Container(
                      height: size.height / 2.5,
                      width: size.width / 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: chatMap['message'] != "" && widget.isDeviceConnected == true ? null : Alignment.center,
                      child: chatMap['message'] != "" && widget.isDeviceConnected == true ? ClipRRect(borderRadius: BorderRadius.circular(18.0),child: Image.network(chatMap['message'], fit: BoxFit.cover,)) : const CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ],
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
                color: Colors.black87,
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
        } else if(chatMap['type']  == 'location') {
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
              GestureDetector(
                onLongPress: (){
                  if(chatMap['sendBy'] == widget.user.displayName){
                    changeMessage(index, length, chatMap['message'], chatMap['type']);
                  }
                },
                child: Container(
                  width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                  alignment: chatMap['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: size.width / 2,
                    // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade800,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.blueAccent,
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    "Vi tri truc tiep",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    // int.parse(map['timeSpend'].toString()) < 60 ?
                                    "Da bat dau chia se" ,
                                    // : (map['timeSpend'] / 60).toString() + "p "+ (map['timeSpend'] % 60).toString() + "s",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10,),
                        GestureDetector(
                          onTap: (){
                            takeUserLocation(chatMap['uid']);
                          },
                          child: Container(
                            // margin: EdgeInsets.only(right: 5,left: 0),
                            width: size.width,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade400,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                  "Xem vi tri"
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if(chatMap['type'] == 'locationed') {
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
              GestureDetector(
                onLongPress: (){
                  if(chatMap['sendBy'] == widget.user.displayName){
                    changeMessage(index, length, chatMap['message'], chatMap['type']);
                  }
                },
                child: Container(
                  width: chatMap['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                  alignment: chatMap['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: size.width / 1.8,
                    // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade700,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.blueAccent,
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10,),
                            Container(
                              child: Text(
                                "Chia sẻ vị trí đã kết thúc",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        else {
          return Container();
        }
      }
    });
  }

  bool? isLocationed;
  void checkUserisLocationed() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.groupChatId).get().then((value) {
      isLocationed = value.data()!['isLocationed'];
    });
    if(isLocationed == true) {
      return showTurnOffLocation();
    } else {
      return showTurnOnLocation();
    }
  }

  void showTurnOnLocation() {
    showModalBottomSheet(
        backgroundColor: Colors.grey,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              turnOnLocation();
              Navigator.pop(context);
            },
            child: Container(
              height: 70,
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Share your location",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }
    );
  }

  void turnOnLocation() async {
    await getLocation().then((value) {
      lat = '${value.latitude}';
      long = '${value.longitude}';
    });
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.groupChatId).set({
      'isLocationed' : true,
      'lat' : lat,
      'long' : long,
    });
    sendLocation();
  }

  void sendLocation() async {
    String messageId = Uuid().v1();
    await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(messageId).set({
      'sendBy' : widget.user.displayName,
      'message' : '${widget.user.displayName} đã gửi một vị trí trực tiếp',
      'type' : "location",
      'time' :  timeForMessage(DateTime.now().toString()),
      'avatar' : avatarUrl,
      'messageId' : messageId,
      'uid' : _auth.currentUser!.uid,
      'timeStamp' : DateTime.now(),
    });

    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.groupChatId).update({
      'messageId' : messageId,
    });

    for(int i = 0 ; i < memberList.length ; i++) {
      await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
        'lastMessage' : "${widget.user.displayName} đã gửi một vị trí trực tiếp",
        'type' : "location",
        'time' : timeForMessage(DateTime.now().toString()),
        'timeStamp' : DateTime.now(),
        'isRead' : false,
      });
    }
    // scrollToIndex();
  }

  String? userLat;
  String? userLong;
  void takeUserLocation(String uid) async {
    await _firestore.collection('users').doc(uid).collection('location').doc(widget.groupChatId).get().then((value) {
      userLat = value.data()!['lat'];
      userLong = value.data()!['long'];
    });
    openMap(userLat!, userLong!);
  }

  void showTurnOffLocation() {
    showModalBottomSheet(
        backgroundColor: Colors.grey,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              turnOffLocation();
              Navigator.pop(context);
            },
            child: Container(
              height: 70,
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Turn off locationed",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }
    );
  }

  void turnOffLocation() async {
    String? messageId;
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.groupChatId).update({
      'isLocationed' : false,
    });
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.groupChatId).get().then((value){
      messageId =  value.data()!['messageId'];
    });
    await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(messageId).update({
      'type' : 'locationed' ,
    });
  }

  void changeMessage(int index, int length, String message, String messageType) {
    showModalBottomSheet(
        backgroundColor: Colors.grey,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: messageType == 'text' ? 100 : 70,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      removeMessage(index, length);
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      child: Text(
                        "Remove message",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                messageType == 'text' ?
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      showEditForm(index, length, message);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Colors.black26,
                                  width: 1.5
                              )
                          )
                      ),
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      child: Text(
                        "Edit message",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ) : Container(),
              ],
            ),
          );
        }
    );
  }

  void showEditForm(int index, int length, String message) {
    TextEditingController _controller = TextEditingController();
    setState(() {
      _controller.text = message;
    });
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
            content: TextField(
              controller: _controller,
              onSubmitted: (text) {
                editMessage(index, length, text);
                Navigator.pop(context);
              },
            )
        );
      },
    );
  }
  void editMessage(int index, int length, String message) async {
    String? str;
    await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').orderBy('timeStamp').get().then((value) {
      str = value.docs[index].id;
    });
    if(str != null) {
      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(str).update({
        'message' : message,
        'status' : 'edited',
      });
      if(index == length - 1){
        for(int i = 0; i < memberList.length ; i++ ){
          await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
            'lastMessage' : '${widget.user.displayName}: $message',
            'time' : timeForMessage(DateTime.now().toString()),
            'timeStamp' : DateTime.now(),
            'isRead' : false,
          });
        }
      }
    }
  }

  void removeMessage(int index, int length) async {
    String? str;
    await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').orderBy('timeStamp').get().then((value) {
      str = value.docs[index].id;
    });
    if(str != null) {
      await _firestore.collection('groups').doc(widget.groupChatId).collection('chats').doc(str).update({
        'message' : 'Bạn đã xóa một tin nhắn',
        'status' : 'removed',
      });
      if(index == length - 1){
        for(int i = 0; i < memberList.length; i++) {
          await _firestore.collection('users').doc(memberList[i]['uid']).collection('chatHistory').doc(widget.groupChatId).update({
            'lastMessage' : '${widget.user.displayName} đã xóa một tin nhắn',
            'time' : timeForMessage(DateTime.now().toString()),
            'timeStamp' : DateTime.now(),
            'isRead' : false,
          });
        }
      }
    }
  }

  showDialogInternetCheck() => showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text(
          'No Connection',
          style: TextStyle(
            letterSpacing: 0.5,
          ),
        ),
        content: const Text(
          'Please check your internet connectivity',
          style: TextStyle(
              letterSpacing: 0.5,
              fontSize: 12
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text(
                'OK',
                style: TextStyle(
                    letterSpacing: 0.5,
                    fontSize: 15
                ),
              )
          )
        ],
      )
  );
}
