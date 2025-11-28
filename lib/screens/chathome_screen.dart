// import 'dart:html';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/call_log_screen.dart';
// import 'package:my_porject/screens/callscreen/pickup/pickup_layout.dart';
import 'package:my_porject/screens/chat_bot/chat_bot.dart';
import 'package:my_porject/screens/finding_screen.dart';
import 'package:my_porject/screens/setting.dart';
import 'package:my_porject/screens/group/group_chat.dart';
import 'package:my_porject/widgets/conversationList.dart';
import 'package:provider/provider.dart';
import 'package:my_porject/resources/methods.dart';
import '../db/log_repository.dart';
import 'chat_screen.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  User user;
  HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late UserProvider userProvider;

  late StreamSubscription subscription;
  var isDeviceConnected = true;
  bool isAlertSet = false;

  getConnectivity() async {
    return subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      isDeviceConnected = await InternetConnection().hasInternetAccess;
      setState(() {});
      if (!isDeviceConnected && isAlertSet == false) {
        showDialogInternetCheck();
        setState(() {
          isAlertSet = true;
        });
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
    changeStatus("Online");
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUser();
    });
    LogRepository.init(dbName: _auth.currentUser!.uid);
    super.initState();
    getConnectivity();
  }

  @override
  void dispose() {
    // subscription.cancel();
    super.dispose();
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
              style: TextStyle(letterSpacing: 0.5, fontSize: 12),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'Cancel');
                    setState(() {
                      isAlertSet = false;
                    });
                    isDeviceConnected =
                        await InternetConnection().hasInternetAccess;
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(letterSpacing: 0.5, fontSize: 15),
                  ))
            ],
          ));

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status": status,
    });
  }

  void changeStatus(String statuss) async {
    int? n;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('chatHistory')
        .get()
        .then((value) => {n = value.docs.length});
    for (int i = 0; i < n!; i++) {
      String? uId;
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('chatHistory')
          .get()
          .then((value) async {
        if (value.docs[i]['datatype'] == 'p2p') {
          uId = value.docs[i]['uid'];
          await _firestore
              .collection('users')
              .doc(uId)
              .collection('chatHistory')
              .doc(_auth.currentUser!.uid)
              .update({
            'status': statuss,
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
      changeStatus('Online');
    } else {
      setStatus("Offline");
      changeStatus('Offline');
    }
  }

  int _selectedIndex = 0;

  Widget body(int index) {
    if (index == 0) {
      return listChat(widget.user);
    } else if (index == 2) {
      return const CallLogScreen();
    } else if (index == 1) {
      return GroupChatHomeScreen(
        user: widget.user,
        isDeviceConnected: isDeviceConnected,
      );
    } else {
      return Container();
    }
  }

  Widget appBar(int index) {
    if (index == 0 || index == 1 || index == 2) {
      return searchAndStatusBar();
    } else {
      return Setting(
        user: widget.user,
        isDeviceConnected: isDeviceConnected,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController _search = TextEditingController();

  bool isLoading = false;

  void onSearch() async {
    showSearch(
      context: context,
      delegate:
          CustomSearch(user: widget.user, isDeviceConnected: isDeviceConnected),
    );
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: appBar(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.grey[900],
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: "Chats",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group),
                  label: "Groups",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.call_outlined),
                  activeIcon: Icon(Icons.call),
                  label: "Calls",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: "Settings",
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }

  Widget listChat(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, left: 20, bottom: 8),
          child: Text('Recent',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: StreamBuilder(
                stream: _firestore
                    .collection('users')
                    .doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0")
                    .collection('chatHistory')
                    .orderBy('timeStamp', descending: true)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 5),
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data?.docs[index]
                            .data() as Map<String, dynamic>;
                        return ConversationList(
                          chatHistory: map,
                          user: widget.user,
                          isDeviceConnected: isDeviceConnected,
                        );
                      },
                    );
                  } else {
                    return Container();
                  }
                }),
          ),
        ),
      ],
    );
  }

  Widget searchAndStatusBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Messages",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (isDeviceConnected == false) {
                      showDialogInternetCheck();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatBot(
                                  user: widget.user,
                                )),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[900],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.smart_toy_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "AI Bot",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            autofocus: false,
            style: TextStyle(color: Colors.grey[900], fontSize: 15),
            decoration: InputDecoration(
              hintText: "Search messages...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[400],
                size: 22,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  )),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[400]!,
                    width: 1.5,
                  )),
            ),
            controller: _search,
            onTap: () {
              if (isDeviceConnected == false) {
                showDialogInternetCheck();
              } else {
                onSearch();
              }
            },
          ),
        ),
        const SizedBox(
          height: 7,
        ),
        // isDeviceConnected == false
        //     ? Container(
        //   alignment: Alignment.center,
        //   width: MediaQuery.of(context).size.width,
        //   height: MediaQuery.of(context).size.height / 30,
        //   // color: Colors.red,
        //   child: const Text(
        //     'No Internet Connection',
        //     style: TextStyle(
        //       fontSize: 15,
        //       fontWeight: FontWeight.w500,
        //     ),
        //   ),
        // ) : Container(),
        StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (_, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.active:
                  final states = snapshot.data;
                  if (states != null &&
                      states.contains(ConnectivityResult.none)) {
                    return Container(
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
                    );
                  }
                  return Container();
                default:
                  return Container();
              }
            }),
        const SizedBox(
          height: 5,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: StreamBuilder(
              stream: _firestore
                  .collection('users')
                  .doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0")
                  .collection('chatHistory')
                  .orderBy('status', descending: false)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.data != null) {
                  return Row(
                    textDirection: TextDirection.rtl,
                    children: List.generate((snapshot.data?.docs.length as int),
                        (index) {
                      Map<String, dynamic> map = snapshot.data?.docs[index]
                          .data() as Map<String, dynamic>;
                      String roomId = ChatRoomId()
                          .chatRoomId(widget.user.displayName, map['name']);
                      if (map['datatype'] != 'group') {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ChatScreen(
                                chatRoomId: roomId,
                                userMap: map,
                                user: widget.user,
                                isDeviceConnected: isDeviceConnected,
                              );
                            }));
                          },
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 5, right: 10),
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      children: <Widget>[
                                        Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                  map['avatar'],
                                                ),
                                                fit: BoxFit.cover,
                                              )),
                                        ),
                                        map['status'] == 'Online'
                                            ? Positioned(
                                                top: 38,
                                                left: 42,
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF66BB6A),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFFFFFFF),
                                                        width: 3,
                                                      )),
                                                ),
                                              )
                                            : Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                        image: NetworkImage(
                                                            map['avatar']),
                                                        fit: BoxFit.cover)),
                                              ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    width: 75,
                                    child: Align(
                                      child: Text(
                                        map['name'] ?? "UserName",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        );
                      } else {
                        return Container();
                      }
                    }),
                  );
                } else {
                  return Container();
                }
              }),
        ),
        const SizedBox(
          height: 5,
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: body(_selectedIndex),
          ),
        ),
      ],
    );
  }
}
