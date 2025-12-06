// import 'dart:html';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_porject/services/cache_service.dart';
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
import 'package:my_porject/screens/private_chat_screen.dart';
import 'package:my_porject/widgets/conversationList.dart';
// Note: PrivateChatService is used in conversationList.dart, not directly here
import 'package:provider/provider.dart';
import 'package:my_porject/resources/methods.dart';
import '../db/log_repository.dart';
import '../configs/app_theme.dart';
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
    // Check if user has locked their status
    final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    final bool isStatusLocked = userDoc.data()?['isStatusLocked'] ?? false;
    
    // If status is locked, set to "Offline" regardless
    final String actualStatus = isStatusLocked ? "Offline" : status;
    
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status": actualStatus,
    });
  }

  // Optimized: Use batch writes and single query instead of N queries
  void changeStatus(String statuss) async {
    // Check if user has locked their status using cache
    final cacheService = CacheService();
    final cachedUser = await cacheService.getUser(_auth.currentUser!.uid);
    final bool isStatusLocked = cachedUser?['isStatusLocked'] ?? false;
    
    // If status is locked, don't update
    if (isStatusLocked) {
      return;
    }
    
    try {
      // Single query to get all chat history
      final chatHistorySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('chatHistory')
          .where('datatype', isEqualTo: 'p2p')
          .get();
      
      if (chatHistorySnapshot.docs.isEmpty) return;
      
      // Use batch write for better performance (max 500 operations per batch)
      WriteBatch batch = _firestore.batch();
      int operationCount = 0;
      
      for (final doc in chatHistorySnapshot.docs) {
        final uId = doc['uid'];
        if (uId != null) {
          final ref = _firestore
              .collection('users')
              .doc(uId)
              .collection('chatHistory')
              .doc(_auth.currentUser!.uid);
          
          batch.update(ref, {'status': statuss});
          operationCount++;
          
          // Commit batch every 400 operations to stay under limit
          if (operationCount >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }
      }
      
      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Silently fail - status update is not critical
      debugPrint('Error updating status: $e');
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.textWhite : AppTheme.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        backgroundColor: AppTheme.backgroundLight,
        body: appBar(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Chats"),
                  _buildNavItem(1, Icons.groups_outlined, Icons.groups_rounded, "Groups"),
                  _buildNavItem(2, Icons.call_outlined, Icons.call_rounded, "Calls"),
                  _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, "Settings"),
                ],
              ),
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
          child: const Text('Recent',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
        ),
        Expanded(
          // Optimized: Remove SingleChildScrollView + shrinkWrap for better performance
          child: StreamBuilder(
              stream: _firestore
                  .collection('users')
                  .doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0")
                  .collection('chatHistory')
                  .orderBy('timeStamp', descending: true)
                  .limit(50) // Limit for better performance
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.data != null) {
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    padding: const EdgeInsets.only(top: 5),
                    // Optimized: Use default physics for proper scrolling
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Optimized: Increase cache extent for smoother scrolling
                    cacheExtent: 500,
                    // Optimized: Add repaint boundaries
                    addRepaintBoundaries: true,
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
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
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
                  style: AppTheme.headlineLarge.copyWith(
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    // Private Chats Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivateChatScreen(
                              user: widget.user,
                              isDeviceConnected: isDeviceConnected,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppTheme.accentGradient,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.textWhite,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AI Bot Button
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
                          color: AppTheme.primaryDark,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.auto_awesome,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "AI",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            autofocus: false,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: AppTheme.searchInputDecoration(hintText: "Search messages..."),
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
                                                      color: AppTheme.online,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppTheme.backgroundWhite,
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
              color: AppTheme.backgroundLight,
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
