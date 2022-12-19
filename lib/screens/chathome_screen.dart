// import 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/callscreen/pickup/pickup_layout.dart';
import 'package:my_porject/screens/chat_bot/chat_bot.dart';
import 'package:my_porject/screens/group/finding_screen.dart';
import 'package:my_porject/screens/setting.dart';
import 'package:my_porject/screens/group/group_chat.dart';
import 'package:my_porject/widgets/conversationList.dart';
import 'package:provider/provider.dart';
import 'package:my_porject/resources/methods.dart';
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

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
    changeStatus("Online");
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUser();
    });
    super.initState();
  }


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
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').where('datatype', isNotEqualTo: 'group').get().then((value){
        uId = value.docs[i]['uid'] ;
      });
      await _firestore.collection('users').doc(uId).collection('chatHistory').doc(_auth.currentUser!.uid).update({
        'status' : statuss,
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
    } else if(index == 1) {
      return GroupChatHomeScreen(user: widget.user,);
    } else {
      return Container();
    }
  }

  Widget appBar(int index) {
    if(index == 0 || index == 1){
      return searchAndStatusBar();
    } else {
      return Setting(user: widget.user);
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
      delegate: CustomSearch(user: widget.user),
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
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.message_rounded),
                label: "Message",
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                label: "Group",
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
          margin: EdgeInsets.only(top: 15,left: 15),
          child: Text(
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
                stream: _firestore.collection('users').doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0").collection('chatHistory').orderBy('time',descending: true).snapshots(),
                builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                  if(snapshot.data!= null){
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 5),
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                        return ConversationList(chatHistory: map,user: widget.user);
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
                        Text(
                          "ChatBot",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width : 5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 16, right: 16, left: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search..",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20,),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.all(8.0),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.shade100,
                  )
              ),
            ),
            controller: _search,
            onTap: onSearch,
          ),
        ),
        SizedBox(height: 20,),
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
                                  return ChatScreen(chatRoomId: roomId, userMap: map, user: widget.user,);
                                })
                            );
                          },
                          child: Padding(
                              padding: EdgeInsets.only(left:5,right: 10),
                              child :Column(
                                children: <Widget>[
                                  Container(
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
                                                image: NetworkImage(
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



