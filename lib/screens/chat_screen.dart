import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:my_porject/resources/methods.dart';
// import 'package:my_porject/screens/callscreen/call_utils.dart';
// import 'package:my_porject/screens/callscreen/pickup/pickup_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:my_porject/models/user_model.dart';
import 'package:my_porject/services/encrypted_chat_service.dart';
import 'package:my_porject/screens/chat_settings_screen.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  Map<String, dynamic> userMap;

  late String chatRoomId;

  bool isDeviceConnected;

  User user;

  ChatScreen({
    key,
    required this.chatRoomId,
    required this.userMap,
    required this.user,
    required this.isDeviceConnected,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String email = widget.userMap['email'];

  bool isLoading = false;

  // Cache for decrypted messages to prevent re-decryption
  final Map<String, String> _decryptedMessagesCache = {};

  @override
  void initState() {
    getConnectivity();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          showEmoji = false;
        });
      }
    });
    updateIsReadMessage();
    getUserInfo();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    updateIsReadMessage();
    super.dispose();
  }

  updateIsReadMessage() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('chatHistory')
        .doc(widget.userMap['uid'])
        .update({
      'isRead': true,
    });
  }

  late StreamSubscription subscription;

  getConnectivity() async {
    return subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      widget.isDeviceConnected = await InternetConnection().hasInternetAccess;
      if (mounted) {
        setState(() {});
      }
    });
  }

  late Userr receiver;
  late Userr sender;
  late String lat;
  late String long;

  // Helper method to get decrypted message text with caching
  Future<String> _getMessageText(Map<String, dynamic> map, String messageId) async {
    if (map['encrypted'] == true) {
      // Check cache first
      if (_decryptedMessagesCache.containsKey(messageId)) {
        return _decryptedMessagesCache[messageId]!;
      }
      
      // Decrypt and cache
      final decryptedText = await EncryptedChatService.decryptMessage(map);
      _decryptedMessagesCache[messageId] = decryptedText;
      return decryptedText;
    }
    return map['message'] ?? '';
  }

  showDialogInternetCheck() => showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.grey[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  'No Connection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
            content: Text(
              'Please check your internet connectivity and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, 'OK');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 15)),
              ),
            ],
          ));

  void getUserInfo() async {
    receiver = Userr(
      uid: widget.userMap['uid'],
      name: widget.userMap['name'],
      avatar: widget.userMap['avatar'],
      email: widget.userMap['email'],
      status: widget.userMap['status'],
    );
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((value) {
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
    if (message.isNotEmpty) {
      // Try to send encrypted message
      final canEncrypt =
          await EncryptedChatService.canEncryptChat(widget.userMap['uid']);

      bool sent = false;
      if (canEncrypt) {
        // Send encrypted message
        sent = await EncryptedChatService.sendEncryptedMessage(
          recipientUid: widget.userMap['uid'],
          message: message,
          chatRoomId: widget.chatRoomId,
          additionalData: {
            'time': timeForMessage(DateTime.now().toString()),
          },
        );
      }

      // Fallback to unencrypted if encryption not available
      if (!sent) {
        Map<String, dynamic> messages = {
          'sendBy': _auth.currentUser!.displayName,
          'message': message,
          'encrypted': false,
          'type': "text",
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        };
        await _firestore
            .collection('chatroom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .add(messages);
      }
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'user1': widget.user.displayName,
        'user2': widget.userMap['name'],
        'lastMessage': message,
        'type': "text",
      });
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('chatHistory')
          .doc(widget.userMap['uid'])
          .set({
        'lastMessage': "Bạn: $message",
        'type': "text",
        'name': widget.userMap['name'],
        'time': timeForMessage(DateTime.now().toString()),
        'uid': widget.userMap['uid'],
        'avatar': widget.userMap['avatar'],
        'status': widget.userMap['status'],
        'datatype': 'p2p',
        'timeStamp': DateTime.now(),
        'isRead': true,
      });
      String? currentUserAvatar;
      String? status;
      await _firestore
          .collection("users")
          .where("email", isEqualTo: _auth.currentUser!.email)
          .get()
          .then((value) {
        currentUserAvatar = value.docs[0]['avatar'];
        status = value.docs[0]['status'];
      });
      await _firestore
          .collection('users')
          .doc(widget.userMap['uid'])
          .collection('chatHistory')
          .doc(_auth.currentUser!.uid)
          .set({
        'lastMessage': message,
        'type': "text",
        'name': widget.user.displayName,
        'time': timeForMessage(DateTime.now().toString()),
        'uid': _auth.currentUser!.uid,
        'avatar': currentUserAvatar,
        'status': status,
        'datatype': 'p2p',
        'timeStamp': DateTime.now(),
        'isRead': false,
      });
    } else {
      print("Enter some text");
    }
  }

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();

    int status = 1;

    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      'sendBy': widget.user.displayName,
      'message': _message.text,
      'type': "img",
      'time': timeForMessage(DateTime.now().toString()),
      'timeStamp': DateTime.now(),
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();
      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({
        'message': imageUrl,
      });
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'user1': widget.user.displayName,
        'user2': widget.userMap['name'],
        'lastMessage': "Bạn đã gửi 1 ảnh",
        'type': "img",
        'uid': widget.userMap['uid'],
      });
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('chatHistory')
          .doc(widget.userMap['uid'])
          .set({
        'lastMessage': "Bạn đã gửi 1 ảnh",
        'type': "img",
        'name': widget.userMap['name'],
        'time': timeForMessage(DateTime.now().toString()),
        'uid': widget.userMap['uid'],
        'avatar': widget.userMap['avatar'],
        'status': widget.userMap['status'],
        'datatype': 'p2p',
        'timeStamp': DateTime.now(),
        'isRead': true,
      });
      String? currentUserAvatar;
      String? status;
      await _firestore
          .collection("users")
          .where("email", isEqualTo: _auth.currentUser!.email)
          .get()
          .then((value) {
        currentUserAvatar = value.docs[0]['avatar'];
        status = value.docs[0]['status'];
      });
      await _firestore
          .collection('users')
          .doc(widget.userMap['uid'])
          .collection('chatHistory')
          .doc(_auth.currentUser!.uid)
          .set({
        'lastMessage': "${widget.user.displayName} đã gửi 1 ảnh",
        'type': "img",
        'name': widget.user.displayName,
        'time': timeForMessage(DateTime.now().toString()),
        'uid': _auth.currentUser!.uid,
        'avatar': currentUserAvatar,
        'status': status,
        'datatype': 'p2p',
        'timeStamp': DateTime.now(),
        'isRead': false,
      });
    }
  }

  late ScrollController controller = ScrollController();
  late int index;

  void liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 100);

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
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
        config: const Config(
            // columns: 7,  // Deprecated in grouped_list 6.0.0
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false, // Disable default back button
          backgroundColor: Colors.grey[900],
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          flexibleSpace: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.grey[100],
                      size: 22,
                    ),
                  ),
                  const SizedBox(
                    width: 2,
                  ),
                  CircleAvatar(
                    backgroundImage:
                        CachedNetworkImageProvider(widget.userMap['avatar']),
                    maxRadius: 20,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          widget.userMap['name'],
                          style: TextStyle(
                              fontSize: 17, 
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[100]),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection("users")
                              .doc(widget.userMap['uid'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              return Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: snapshot.data!['status'].toLowerCase().contains('online') 
                                          ? Colors.greenAccent 
                                          : Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    snapshot.data!['status'],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const Text('');
                            }
                          },
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (widget.isDeviceConnected == false) {
                        showDialogInternetCheck();
                      } else {
                        // Video call temporarily disabled - Agora RTC Engine needs upgrade
                        // await CallUtils.dial(
                        //   from: sender,
                        //   to: receiver,
                        //   context: context,
                        // );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Video call feature temporarily disabled'),
                            backgroundColor: Colors.grey[700],
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.video_call_outlined,
                      color: Colors.grey[300],
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatSettingsScreen(
                            chatRoomId: widget.chatRoomId,
                            userMap: widget.userMap,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.grey[300],
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: isLoading
            ? Container(
                height: size.height,
                width: size.width,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: () {
                  return abc();
                },
                child: Column(
                  children: <Widget>[
                    widget.isDeviceConnected == false
                        ? Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_off, color: Colors.grey[700], size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'No Internet Connection',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('chatroom')
                            .doc(widget.chatRoomId)
                            .collection('chats')
                            .orderBy('timeStamp', descending: false)
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          // Only auto-scroll when messages change, not on every rebuild
                          if (snapshot.hasData) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (controller.hasClients && 
                                  controller.position.pixels < controller.position.maxScrollExtent - 100) {
                                controller.animateTo(
                                  controller.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          }
                          if (snapshot.data != null) {
                            return GroupedListView<
                                QueryDocumentSnapshot<Object?>, String>(
                              elements: snapshot.data?.docs
                                  as List<QueryDocumentSnapshot<Object?>>,
                              shrinkWrap: true,
                              groupBy: (element) => element['time'],
                              padding: const EdgeInsets.only(bottom: 80), // Add padding to prevent input box from covering last message
                              groupSeparatorBuilder: (String groupByValue) =>
                                  Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${groupByValue.substring(11, 16)}, ${groupByValue.substring(0, 10)}",
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              indexedItemBuilder: (context, element, index) {
                                Map<String, dynamic> map =
                                    element.data() as Map<String, dynamic>;
                                return messages(
                                    size,
                                    map,
                                    widget.userMap,
                                    index,
                                    snapshot.data?.docs.length as int,
                                    context,
                                    element.id); // Pass document ID for caching
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
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!, width: 0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                                // Attachment menu button
                                IconButton(
                                  onPressed: () {
                                    _showAttachmentMenu();
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey[600],
                                  ),
                                  iconSize: 24,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                // Text input field
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 36,
                                      maxHeight: 100,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            focusNode: focusNode,
                                            controller: _message,
                                            maxLines: null,
                                            textInputAction: TextInputAction.newline,
                                            style: TextStyle(
                                              color: Colors.grey[900],
                                              fontSize: 15,
                                              height: 1.3,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Message",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 15,
                                              ),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        // Emoji button
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              focusNode.unfocus();
                                              focusNode.canRequestFocus = false;
                                              showEmoji = !showEmoji;
                                            });
                                          },
                                          icon: Icon(
                                            showEmoji 
                                              ? Icons.keyboard_outlined
                                              : Icons.emoji_emotions_outlined,
                                            color: Colors.grey[600],
                                          ),
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                // Voice/Send button with ValueListenableBuilder to prevent flickering
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _message,
                                  builder: (context, value, child) {
                                    return Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          if (value.text.trim().isNotEmpty) {
                                            onSendMessage();
                                          } else {
                                            _showVoiceRecording();
                                          }
                                        },
                                        icon: Icon(
                                          value.text.trim().isNotEmpty
                                            ? Icons.send
                                            : Icons.mic,
                                          color: Colors.white,
                                        ),
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                      ),
                                    );
                                  },
                                ),
                              ],
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

  Widget messages(
      Size size,
      Map<String, dynamic> map,
      Map<String, dynamic> userMap,
      int index,
      int length,
      BuildContext context,
      String messageId) {
    if (map['status'] == 'removed') {
      return Row(
        children: [
          const SizedBox(
            width: 2,
          ),
          map['sendBy'] != widget.user.displayName
              ? SizedBox(
                  height: size.width / 13,
                  width: size.width / 13,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userMap['avatar']),
                    maxRadius: 30,
                  ),
                )
              : Container(),
          GestureDetector(
            onLongPress: () {},
            child: Container(
              width: map['sendBy'] == widget.user.displayName
                  ? size.width * 0.98
                  : size.width * 0.7,
              alignment: map['sendBy'] == widget.user.displayName
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: size.width / 1.5),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
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
      if (map['type'] == "text") {
        return Row(
          children: [
            const SizedBox(
              width: 2,
            ),
            map['sendBy'] != widget.user.displayName
                ? SizedBox(
                    height: size.width / 13,
                    width: size.width / 13,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(userMap['avatar']),
                      maxRadius: 30,
                    ),
                  )
                : Container(),
            GestureDetector(
              onLongPress: () {
                if (map['sendBy'] == widget.user.displayName) {
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName
                    ? size.width * 0.98
                    : size.width * 0.7,
                alignment: map['sendBy'] == widget.user.displayName
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: size.width / 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: map['sendBy'] == widget.user.displayName
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                    color: map['sendBy'] == widget.user.displayName
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: FutureBuilder<String>(
                    future: _getMessageText(map, messageId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Decrypting...',
                          style: TextStyle(
                              color: map['sendBy'] == widget.user.displayName
                                  ? Colors.white70
                                  : Colors.grey[600],
                              fontSize: 15,
                              fontStyle: FontStyle.italic),
                        );
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (map['encrypted'] == true)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.lock_outline,
                                  color: map['sendBy'] == widget.user.displayName
                                      ? Colors.green[300]
                                      : Colors.green[600],
                                  size: 14),
                            ),
                          Flexible(
                            child: Text(
                              snapshot.data ?? map['message'] ?? '',
                              style: TextStyle(
                                  color: map['sendBy'] == widget.user.displayName
                                      ? Colors.white
                                      : Colors.grey[900],
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    },
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
            const SizedBox(
              width: 2,
            ),
            map['sendBy'] != widget.user.displayName
                ? Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: size.width / 13,
                    width: size.width / 13,
                    child: CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(userMap['avatar']),
                      maxRadius: 30,
                    ),
                  )
                : Container(),
            GestureDetector(
              onLongPress: () {
                if (map['sendBy'] == widget.user.displayName) {
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                height: size.height / 2.5,
                width: map['sendBy'] == widget.user.displayName
                    ? size.width * 0.98
                    : size.width * 0.77,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                alignment: map['sendBy'] == widget.user.displayName
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => ShowImage(
                              imageUrl: map['message'],
                              isDeviceConnected: widget.isDeviceConnected,
                            )),
                  ),
                  child: Container(
                    height: size.height / 2.5,
                    width: size.width / 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade300,
                    ),
                    alignment:
                        map['message'] != "" && widget.isDeviceConnected == true
                            ? null
                            : Alignment.center,
                    child:
                        map['message'] != "" && widget.isDeviceConnected == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18.0),
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  imageUrl: map['message'],
                                ))
                            : const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (map['type'] == "videocall") {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 2,
            ),
            map['sendBy'] != widget.user.displayName
                ? Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    height: size.width / 13,
                    width: size.width / 13,
                    child: CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(userMap['avatar']),
                      maxRadius: 30,
                    ),
                  )
                : Container(),
            GestureDetector(
              onLongPress: () {
                if (map['sendBy'] == widget.user.displayName) {
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName
                    ? size.width * 0.98
                    : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: size.width / 2.8,
                  // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade700,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.grey,
                        ),
                        child: const Icon(
                          Icons.call_sharp,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Column(
                        children: const [
                          Text(
                            "Video Call",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          // Text(
                          //   // int.parse(map['timeSpend'].toString()) < 60 ?
                          //   map['timeSpend'].toString() + "s" ,
                          //   // : (map['timeSpend'] / 60).toString() + "p "+ (map['timeSpend'] % 60).toString() + "s",
                          //   style: TextStyle(
                          //     fontSize: 13,
                          //     color: Colors.grey.shade300,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (map['type'] == 'location') {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 2,
            ),
            map['sendBy'] != widget.user.displayName
                ? Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    height: size.width / 13,
                    width: size.width / 13,
                    child: CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(userMap['avatar']),
                      maxRadius: 30,
                    ),
                  )
                : Container(),
            GestureDetector(
              onLongPress: () {
                if (map['sendBy'] == widget.user.displayName) {
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName
                    ? size.width * 0.98
                    : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: size.width / 2,
                  // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade800,
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
                          const SizedBox(
                            width: 0,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "Vị trí trực tiếp",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  // int.parse(map['timeSpend'].toString()) < 60 ?
                                  "Đã bắt đầu chia sẻ",
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
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (map['sendBy'] == widget.user.displayName) {
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
                            child: const Text("Xem vi tri"),
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
      } else if (map['type'] == 'locationed') {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 2,
            ),
            map['sendBy'] != widget.user.displayName
                ? Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    height: size.width / 13,
                    width: size.width / 13,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(userMap['avatar']),
                      maxRadius: 30,
                    ),
                  )
                : Container(),
            GestureDetector(
              onLongPress: () {
                if (map['sendBy'] == widget.user.displayName) {
                  changeMessage(index, length, map['message'], map['type']);
                }
              },
              child: Container(
                width: map['sendBy'] == widget.user.displayName
                    ? size.width * 0.98
                    : size.width * 0.77,
                alignment: map['sendBy'] == widget.user.displayName
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: size.width / 1.8,
                  // constraints: BoxConstraints( maxWidth: size.width / 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
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
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            "Chia sẻ vị trí đã kết thúc",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
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

  bool? isLocationed;

  void initLocationDoc() async {
    if (isLocationed == false) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('location')
          .doc(widget.userMap['uid'])
          .set({
        'isLocationed': null,
      });
    }
    return checkUserisLocationed();
  }

  void checkUserisLocationed() async {
    if (isLocationed == null) {
      isLocationed = true;
      return showTurnOnLocation();
    } else {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('location')
          .doc(widget.userMap['uid'])
          .get()
          .then((value) {
        isLocationed = value.data()!['isLocationed'];
      });
      if (isLocationed == true) {
        return showTurnOffLocation();
      } else {
        return showTurnOnLocation();
      }
    }
  }

  // Attachment menu bottom sheet
  void _showAttachmentMenu() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Photo & Video
                      _buildAttachmentOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Photo & Video',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          getImage();
                        },
                      ),
                      const SizedBox(height: 12),
                      // Document
                      _buildAttachmentOption(
                        icon: Icons.insert_drive_file_outlined,
                        label: 'Document',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          _pickDocument();
                        },
                      ),
                      const SizedBox(height: 12),
                      // Location
                      _buildAttachmentOption(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.isDeviceConnected == false) {
                            showDialogInternetCheck();
                          } else {
                            initLocationDoc();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Camera
                      _buildAttachmentOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _openCamera();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pick document (placeholder - requires file_picker package)
  void _pickDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Document sharing feature coming soon!'),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Open camera (placeholder)
  void _openCamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Camera feature coming soon!'),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Voice recording (placeholder)
  void _showVoiceRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Voice message feature coming soon!'),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showTurnOnLocation() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      turnOnLocation();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Share your location",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Send your current location to chat",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
  }

  void turnOnLocation() async {
    await getLocation().then((value) {
      lat = '${value.latitude}';
      long = '${value.longitude}';
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('location')
        .doc(widget.userMap['uid'])
        .set({
      'isLocationed': true,
      'lat': lat,
      'long': long,
    });
    sendLocation();
  }

  void sendLocation() async {
    String messageId = const Uuid().v1();
    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(messageId)
        .set({
      'sendBy': widget.user.displayName,
      'message': 'Bạn đã gửi một vị trí trực tiếp',
      'type': "location",
      'time': timeForMessage(DateTime.now().toString()),
      'messageId': messageId,
      'timeStamp': DateTime.now(),
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('location')
        .doc(widget.userMap['uid'])
        .update({
      'messageId': messageId,
    });

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('chatHistory')
        .doc(widget.userMap['uid'])
        .set({
      'lastMessage': "Bạn đã gửi một vị trí trực tiếp",
      'type': "location",
      'name': widget.userMap['name'],
      'time': timeForMessage(DateTime.now().toString()),
      'uid': widget.userMap['uid'],
      'avatar': widget.userMap['avatar'],
      'status': widget.userMap['status'],
      'datatype': 'p2p',
      'timeStamp': DateTime.now(),
      'isRead': true,
    });
    String? currentUserAvatar;
    String? status;
    await _firestore
        .collection("users")
        .where("email", isEqualTo: _auth.currentUser!.email)
        .get()
        .then((value) {
      currentUserAvatar = value.docs[0]['avatar'];
      status = value.docs[0]['status'];
    });
    await _firestore
        .collection('users')
        .doc(widget.userMap['uid'])
        .collection('chatHistory')
        .doc(_auth.currentUser!.uid)
        .set({
      'lastMessage': "${widget.user.displayName} da gui mot vi tri truc tiep",
      'type': "location",
      'name': widget.user.displayName,
      'time': timeForMessage(DateTime.now().toString()),
      'uid': _auth.currentUser!.uid,
      'avatar': currentUserAvatar,
      'status': status,
      'datatype': 'p2p',
      'timeStamp': DateTime.now(),
      'isRead': false,
    });
  }

  String? userLat;
  String? userLong;
  void takeUserLocation() async {
    await _firestore
        .collection('users')
        .doc(widget.userMap['uid'])
        .collection('location')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((value) {
      userLat = value.data()!['lat'];
      userLong = value.data()!['long'];
    });
    openMap(userLat!, userLong!);
  }

  void showTurnOffLocation() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      turnOffLocation();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_off,
                              color: Colors.red[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Stop sharing location",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your location will no longer be shared",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
  }

  void turnOffLocation() async {
    String? messageId;
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('location')
        .doc(widget.userMap['uid'])
        .update({
      'isLocationed': false,
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('location')
        .doc(widget.userMap['uid'])
        .get()
        .then((value) {
      messageId = value.data()!['messageId'];
    });
    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(messageId)
        .update({
      'type': 'locationed',
    });
  }

  void changeMessage(
      int index, int length, String message, String messageType) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      "Message Options",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  GestureDetector(
                    onTap: () {
                      removeMessage(index, length);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red[700],
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Delete message",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (messageType == 'text') ...[
                    Divider(height: 1, color: Colors.grey[200]),
                    GestureDetector(
                      onTap: () {
                        showEditForm(index, length, message);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                color: Colors.grey[700],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Edit message",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.grey[700], size: 24),
              const SizedBox(width: 12),
              Text(
                "Edit Message",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          content: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[900],
            ),
            decoration: InputDecoration(
              hintText: "Enter your message...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!, width: 2),
              ),
            ),
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                editMessage(index, length, text);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  editMessage(index, length, _controller.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Save", style: TextStyle(fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  void editMessage(int index, int length, String message) async {
    String? str;
    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .orderBy('timeStamp')
        .get()
        .then((value) {
      str = value.docs[index].id;
    });
    if (str != null) {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(str)
          .update({
        'message': message,
        'status': 'edited',
      });
      if (index == length - 1) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('chatHistory')
            .doc(widget.userMap['uid'])
            .update({
          'lastMessage': 'Bạn: $message',
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
        await _firestore
            .collection('users')
            .doc(widget.userMap['uid'])
            .collection('chatHistory')
            .doc(_auth.currentUser!.uid)
            .update({
          'lastMessage': message,
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
      }
    }
  }

  void removeMessage(int index, int length) async {
    String? str;
    await _firestore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .orderBy('timeStamp')
        .get()
        .then((value) {
      str = value.docs[index].id;
    });
    if (str != null) {
      await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(str)
          .update({
        'message': 'Bạn đã xóa một tin nhắn',
        'status': 'removed',
      });
      if (index == length - 1) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('chatHistory')
            .doc(widget.userMap['uid'])
            .update({
          'lastMessage': 'Bạn đã xóa một tin nhắn',
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
        await _firestore
            .collection('users')
            .doc(widget.userMap['uid'])
            .collection('chatHistory')
            .doc(_auth.currentUser!.uid)
            .update({
          'lastMessage': '${widget.user.displayName} đã xóa một tin nhắn',
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
      }
    }
  }
}

class ShowImage extends StatelessWidget {
  bool isDeviceConnected;
  ShowImage({Key? key, required this.imageUrl, required this.isDeviceConnected})
      : super(key: key);

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: isDeviceConnected == true
            ? CachedNetworkImage(
                imageUrl: imageUrl,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
