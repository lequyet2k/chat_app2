import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:my_porject/resources/methods.dart';
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

  bool isDeviceConnected;

  User user;

  ChatScreen({key, required this.chatRoomId, required this.userMap, required this.user, required  this.isDeviceConnected,});

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
    focusNode.addListener(() {
      if(focusNode.hasFocus) {
        setState(() {
          showEmoji = false;
        });
      }
    });
    updateIsReadMessage();
    controller = ScrollController();
    // WidgetsBinding.instance.addPostFrameCallback((_){
    //   if (controller.hasClients) {
    //     scrollToIndex();
    //   }
    //   scrollToIndex();
    // });
    scrollToIndex();
    getUserInfo();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    updateIsReadMessage();
    super.dispose();
  }

  updateIsReadMessage() async{
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).update({
      'isRead' : true,
    });
  }

  late Userr receiver;
  late Userr sender;
  late String lat;
  late String long;

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

  void getUserInfo() async {

    receiver = Userr(
      uid: widget.userMap['uid'],
      name: widget.userMap['name'],
      avatar: widget.userMap['avatar'],
      email: widget.userMap['email'],
      status: widget.userMap['status'],
    );
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
        'sendBy' : _auth.currentUser!.displayName,
        'message' : message,
        'type' : "text",
        'time' :  timeForMessage(DateTime.now().toString()),
        'timeStamp' : DateTime.now(),
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
        'time' : timeForMessage(DateTime.now().toString()),
        'uid' : widget.userMap['uid'],
        'avatar' : widget.userMap['avatar'],
        'status' : widget.userMap['status'],
        'datatype' : 'p2p',
        'timeStamp' : DateTime.now(),
        'isRead' : true,
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
        'time' : timeForMessage(DateTime.now().toString()),
        'uid' : _auth.currentUser!.uid,
        'avatar' : currentUserAvatar,
        'status' : status,
        'datatype' : 'p2p',
        'timeStamp' : DateTime.now(),
        'isRead' : false,
      });
    } else {
      print("Enter some text");
    }
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
  }

  Future uploadImage() async {

    String fileName =   Uuid().v1();

    int status = 1 ;

    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(fileName).set({
      'sendBy' : widget.user.displayName,
      'message' : _message.text,
      'type' : "img",
      'time' :  timeForMessage(DateTime.now().toString()),
      'timeStamp' : DateTime.now(),
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
        'time' : timeForMessage(DateTime.now().toString()),
        'uid' : widget.userMap['uid'],
        'avatar' : widget.userMap['avatar'],
        'status' : widget.userMap['status'],
        'datatype' : 'p2p',
        'timeStamp' : DateTime.now(),
        'isRead' : true,
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
        'time' : timeForMessage(DateTime.now().toString()),
        'uid' : _auth.currentUser!.uid,
        'avatar' : currentUserAvatar,
        'status' : status,
        'datatype' : 'p2p',
        'timeStamp' : DateTime.now(),
        'isRead' : false,
      });
    }
  }
  late ScrollController controller;
  late int index;
  void scrollToIndex() async {
    final bottomOffset = controller.position.maxScrollExtent;
    controller.animateTo(
      bottomOffset,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }
  
  
  void liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      lat = position.latitude.toString();
      long = position.longitude.toString();
    });
  }
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
        },
      ),
    );
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
              padding: EdgeInsets.only(right: 10),
              child: Row(
                children: <Widget>[
                  IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent,),
                  ),
                  SizedBox(width: 2,),
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(widget.userMap['avatar']),
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
                      onPressed: () async {
                        if(widget.isDeviceConnected == false) {
                          showDialogInternetCheck();
                        } else {
                          await CallUtils.dial(
                            from: sender,
                            to: receiver,
                            context: context,
                          );
                        }
                      },
                      icon: const Icon(Icons.video_call,color: Colors.blueAccent,),
                  ),
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
        ) : RefreshIndicator(
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('timeStamp',descending: false).snapshots(),
                  builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                    if(snapshot.data!= null){
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
                        indexedItemBuilder: (context, element, index) {
                          Map<String, dynamic> map = element.data() as Map<String, dynamic>;
                          return messages(size, map, widget.userMap, index , snapshot.data?.docs.length as int, context);
                        },
                        controller: controller,
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
              Column(
                children: [
                  Container(
                    child: Container(
                      // padding: EdgeInsets.only(bottom: 10,top: 10),
                      height: size.height / 16,
                      width: double.infinity,
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
                                  initLocationDoc();
                                }
                              },
                              icon: Icon(Icons.location_on, color: Colors.blueAccent,),
                          ),
                          // SizedBox(width: 15,),
                          Expanded(
                              child: Container(
                                height: size.height / 20.8,
                                child: TextField(
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade300,
                                    // hintText: "Aa",
                                    // hintStyle: TextStyle(color: Colors.white38),
                                    // contentPadding: EdgeInsets.all(8.0),
                                    prefixIcon: Icon(Icons.abc),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          focusNode.unfocus();
                                          focusNode.canRequestFocus = false;
                                          showEmoji = !showEmoji;
                                        });
                                      },
                                      icon: Icon(Icons.emoji_emotions,color: Colors.blueAccent,),
                                    ) ,
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
      ),
    );
  }
  Widget messages(Size size, Map<String, dynamic> map,Map<String, dynamic> userMap,int index,int length, BuildContext context) {
    if(map['status'] == 'removed') {
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
          GestureDetector(
            onLongPress: (){},
            child: Container(
              width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
              alignment: map['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints( maxWidth: size.width / 1.5),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade200,
                ),
                child: Text(
                  map['message'],
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
            GestureDetector(
              onLongPress: (){
                if(map['sendBy'] == widget.user.displayName){
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
                alignment: map['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.blueAccent,
                  ),
                  child: Text(
                    map['message'],
                    style: TextStyle(color: Colors.white,fontSize: 17),
                  ),
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
                backgroundImage: CachedNetworkImageProvider(userMap['avatar']),
                maxRadius: 30,
              ),
            ): Container(
            ),
            GestureDetector(
              onLongPress: (){
                if(map['sendBy'] == widget.user.displayName){
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
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
                    child: map['message'] != ""? ClipRRect(borderRadius: BorderRadius.circular(18.0),child: Image.network(map['message'], fit: BoxFit.cover,)) : const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        );
      } else if(map['type'] == "videocall"){
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
            GestureDetector(
              onLongPress: (){
                if(map['sendBy'] == widget.user.displayName){
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: size.width / 3,
                  // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade700,
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
            ),
          ],
        );
      } else if(map['type']  == 'location') {
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
            GestureDetector(
              onLongPress: (){
                if(map['sendBy'] == widget.user.displayName){
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
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
                                const Text(
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
                          if(map['sendBy'] == widget.user.displayName){
                            openMap(lat, long);
                          } else {
                            takeUserLocation();
                          }
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
      } else if (map['type']  == 'locationed') {
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
            GestureDetector(
              onLongPress: (){
                if(map['sendBy'] == widget.user.displayName){
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName  ? Alignment.centerRight : Alignment.centerLeft,
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
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.blueAccent,
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10,),
                          Container(
                            child: const Text(
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
      } else {
        return Container();
      }
    }
  }
  bool? isLocationed ;

  void initLocationDoc() async {
    if(isLocationed == false) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).set({
        'isLocationed' : null,
      });
    }
    return checkUserisLocationed();
  }


  void checkUserisLocationed() async {
    if(isLocationed == null) {
      isLocationed = true;
      return showTurnOnLocation();
    } else {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).get().then((value) {
        isLocationed = value.data()!['isLocationed'];
      });
      if(isLocationed == true) {
        return showTurnOffLocation();
      } else {
        print("alaolaoloasdasasfasfas");
        return showTurnOnLocation();
      }
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
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).set({
      'isLocationed' : true,
      'lat' : lat,
      'long' : long,
    });
    sendLocation();
  }

  void sendLocation() async {
    String messageId = Uuid().v1();
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(messageId).set({
      'sendBy' : widget.user.displayName,
      'message' : 'Bạn đã gửi một vị trí trực tiếp',
      'type' : "location",
      'time' :  timeForMessage(DateTime.now().toString()),
      'messageId' : messageId,
      'timeStamp' : DateTime.now(),
    });
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).update({
      'messageId' : messageId,
    });

    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).set({
      'lastMessage' : "Bạn đã gửi một vị trí trực tiếp",
      'type' : "location",
      'name' : widget.userMap['name'],
      'time' : timeForMessage(DateTime.now().toString()),
      'uid' : widget.userMap['uid'],
      'avatar' : widget.userMap['avatar'],
      'status' : widget.userMap['status'],
      'datatype' : 'p2p',
      'timeStamp' : DateTime.now(),
      'isRead' : true,
    });
    String? currentUserAvatar;
    String? status;
    await _firestore.collection("users").where("email" , isEqualTo: _auth.currentUser!.email).get().then((value) {
      currentUserAvatar = value.docs[0]['avatar'];
      status = value.docs[0]['status'];
    });
    await _firestore.collection('users').doc(widget.userMap['uid']).collection('chatHistory').doc(_auth.currentUser!.uid).set({
      'lastMessage' : "${widget.user.displayName} da gui mot vi tri truc tiep",
      'type' : "location",
      'name' : widget.user.displayName,
      'time' : timeForMessage(DateTime.now().toString()),
      'uid' : _auth.currentUser!.uid,
      'avatar' : currentUserAvatar,
      'status' : status,
      'datatype' : 'p2p',
      'timeStamp' : DateTime.now(),
      'isRead' : false,
    });
  }

  String? userLat;
  String? userLong;
  void takeUserLocation() async {
    await _firestore.collection('users').doc(widget.userMap['uid']).collection('location').doc(_auth.currentUser!.uid).get().then((value) {
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
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).update({
      'isLocationed' : false,
    });
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('location').doc(widget.userMap['uid']).get().then((value){
      messageId =  value.data()!['messageId'];
    });
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(messageId).update({
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
                      child: const Text(
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
                      decoration: const BoxDecoration(
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
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('timeStamp').get().then((value) {
      str = value.docs[index].id;
    });
    if(str != null) {
      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(str).update({
        'message' : message,
        'status' : 'edited',
      });
      if(index == length - 1){
        await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).update({
          'lastMessage' : 'Bạn: $message',
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
        await _firestore.collection('users').doc(widget.userMap['uid']).collection('chatHistory').doc(_auth.currentUser!.uid).update({
          'lastMessage' : message,
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
      }
    }
  }

  void removeMessage(int index, int length) async {
    String? str;
    await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').orderBy('timeStamp').get().then((value) {
      str = value.docs[index].id;
    });
    if(str != null) {
      await _firestore.collection('chatroom').doc(widget.chatRoomId).collection('chats').doc(str).update({
        'message' : 'Bạn đã xóa một tin nhắn',
        'status' : 'removed',
      });
      if(index == length - 1){
        await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc(widget.userMap['uid']).update({
          'lastMessage' : 'Bạn đã xóa một tin nhắn',
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
        await _firestore.collection('users').doc(widget.userMap['uid']).collection('chatHistory').doc(_auth.currentUser!.uid).update({
          'lastMessage' : '${widget.user.displayName} đã xóa một tin nhắn',
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
      }
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
