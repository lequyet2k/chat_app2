// import 'dart:html';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/call_log_screen.dart';
import 'package:my_porject/screens/callscreen/pickup/pickup_layout.dart';
import 'package:my_porject/screens/chat_bot/chat_bot.dart';
import 'package:my_porject/screens/finding_screen.dart';
import 'package:my_porject/screens/setting.dart';
import 'package:my_porject/screens/group/group_chat.dart';
import 'package:my_porject/widgets/conversationList.dart';
import 'package:provider/provider.dart';
import 'package:my_porject/resources/methods.dart';
import '../db/log_repository.dart';
import 'chat_screen.dart';

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
    return subscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) async {
            isDeviceConnected = await InternetConnectionChecker().hasConnection;
            setState(() {});
            if(!isDeviceConnected && isAlertSet == false) {
              showDialogInternetCheck();
              setState(() {
                isAlertSet = true;
              });
            }

          }
      );
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
          style: TextStyle(
            letterSpacing: 0.5,
            fontSize: 12
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
                setState(() {
                  isAlertSet = false;
                });
                isDeviceConnected = await InternetConnectionChecker().hasConnection;
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

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status" : status,
    });
  }

  void changeStatus(String statuss) async {
    int? n;
    await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value) => {
      n = value.docs.length
    });
    for(int i = 0 ; i < n! ; i++) {
      String? uId;
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value) async {
        if(value.docs[i]['datatype'] == 'p2p'){
          uId = value.docs[i]['uid'] ;
          await _firestore.collection('users').doc(uId).collection('chatHistory').doc(_auth.currentUser!.uid).update({
            'status' : statuss,
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed) {
      setStatus("Online");
      changeStatus('Online');
    }else {
      setStatus("Offline");
      changeStatus('Offline');
    }
  }
  int _selectedIndex = 0 ;

  Widget body(int index) {
    if(index == 0) {
      return listChat(widget.user);
    } else if(index == 2) {
      return const CallLogScreen();
    } else if(index == 1){
      return GroupChatHomeScreen(user: widget.user, isDeviceConnected: isDeviceConnected,);
    } else {
      return Container();
    }
  }


  Widget appBar(int index) {
    if(index == 0 || index == 1 || index == 2){
      return searchAndStatusBar();
    } else {
      return Setting(user: widget.user, isDeviceConnected: isDeviceConnected,);
    }
  }


  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  final TextEditingController _search = TextEditingController();

  bool isLoading = false;

  void onSearch() async {
    showSearch(
      context: context,
      delegate: CustomSearch(user: widget.user,isDeviceConnected : isDeviceConnected),
    );
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PickUpLayout(
      scaffold: Scaffold(
          body: appBar(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.messenger),
                label: "Message",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: "Group",
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.call),
                label: "Calls",
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                label: "Setting",
              ),
          ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
      ),
    );
  }

  Widget listChat(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15,left: 15),
          child: const Text(
            'Recent Chats',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: StreamBuilder(
                stream: _firestore.collection('users').doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0").collection('chatHistory').orderBy('timeStamp',descending: true).snapshots(),
                builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                  if(snapshot.data!= null){
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 5),
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                        return ConversationList(chatHistory: map,user: widget.user, isDeviceConnected: isDeviceConnected, );
                      },
                    );
                  } else {
                    return Container();
                  }
                }
            ),
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
            padding: EdgeInsets.only(left: 16, top: 10, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Conversations",
                  style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatBot(user: widget.user,)),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.pink[50],
                    ),
                    child: Row(
                      children: <Widget>[
                        Tab(
                          icon: Image.asset( //        <-- Image
                            'assets/icons/chatbot-icon.png',
                            height: 25,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Text(
                          "ChatBot",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width : 5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: "Search..",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20,),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.all(8.0),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade100,
                  )
              ),
            ),
            controller: _search,
            onTap: () {
              if(isDeviceConnected == false) {
                showDialogInternetCheck();
              } else {
                onSearch();
              }
            },
          ),
        ),
        const SizedBox(height: 7 ,),
        isDeviceConnected == false
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
        // StreamBuilder<ConnectivityResult>(
        //   stream: Connectivity().onConnectivityChanged,
        //     builder: (_, snapshot) {
        //       switch(snapshot.connectionState){
        //         case ConnectionState.active :
        //           final state = snapshot.data ;
        //           switch(state) {
        //             case ConnectivityResult.none:
        //               return Container(
        //                 alignment: Alignment.center,
        //                 width: MediaQuery.of(context).size.width,
        //                 height: MediaQuery.of(context).size.height / 30,
        //                 // color: Colors.red,
        //                 child: const Text(
        //                   'No Internet Connection',
        //                   style: TextStyle(
        //                     fontSize: 15,
        //                     fontWeight: FontWeight.w500,
        //                   ),
        //                 ),
        //               );
        //             default :
        //               return Container();
        //           }
        //         default :
        //           return Container();
        //       }
        //     }
        // ),
        const SizedBox(height: 5,),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: StreamBuilder(
              stream: _firestore.collection('users').doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0").collection('chatHistory').orderBy('status',descending: false).snapshots(),
              builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot)  {
                if(snapshot.data!= null){
                  return Row(
                    textDirection: TextDirection.rtl,
                    children: List.generate((snapshot.data?.docs.length as int ), (index) {
                      Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                      String roomId = ChatRoomId().chatRoomId(widget.user.displayName, map['name']);
                      if(map['datatype'] != 'group'){
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context){
                                  return ChatScreen(chatRoomId: roomId, userMap: map, user: widget.user, isDeviceConnected: isDeviceConnected,);
                                })
                            );
                          },
                          child: Padding(
                              padding: const EdgeInsets.only(left:5,right: 10),
                              child :Column(
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
                                                image: CachedNetworkImageProvider(
                                                  map['avatar'],
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                          ),
                                        ),
                                        map['status'] == 'Online'
                                            ? Positioned(
                                          top: 38,
                                          left: 42,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                color: Color(0xFF66BB6A),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Color(0xFFFFFFFF),
                                                  width: 3,
                                                )
                                            ),
                                          ),
                                        )
                                            :Container(
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
                                  SizedBox(
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
                              )
                          ),
                        );
                      } else {
                        return Container();
                      }
                    }),
                  );
                } else {
                  return Container();
                }
              }
          ),
        ),
        SizedBox(height: 5,),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20)),
            ),
            child: body(_selectedIndex),
          ),
        ),
      ],
    );
  }
}




