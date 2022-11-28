// import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/models/chatUsersModel.dart';
import 'package:my_porject/widgets/conversationList.dart';
import 'package:my_porject/screens/finding_screen.dart';
import 'package:my_porject/setting.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Onlineeee");
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status" : status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed) {
      setStatus("Onlinee");
    }else {
      setStatus("Offline");
    }
  }

  int numberOfConversation() {
    AggregateQuerySnapshot query = _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').count().get() as AggregateQuerySnapshot;

    int numberOfDocuments;

    return numberOfDocuments = query.count;
  }

  List storyList = [
    {
      "name": "Le Quyet",
      "imageUrl": "assets/images/user.png",
      "isOnline": true,
      "hasStory": true,
    },
    {
      "name": "Nam Ky",
      "imageUrl": "assets/images/user_2.png",
      "isOnline": false,
      "hasStory": false,
    },
    {
      "name": "Duc",
      "imageUrl": "assets/images/user_3.png",
      "isOnline": true,
      "hasStory": false,
    },
    {
      "name": "Hoang Dang",
      "imageUrl": "assets/images/user_4.png",
      "isOnline": true,
      "hasStory": true,
    },
    {
      "name": "Bao Ngoc",
      "imageUrl": "assets/images/user_5.png",
      "isOnline": false,
      "hasStory": false,
    },
  ];
  int _selectedIndex = 0 ;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if(index == 3) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Setting()),
      );
    }
  }

  final TextEditingController _search = TextEditingController();

  late Map<String, dynamic> userMap;

  bool isLoading = false;

  void onSearch() async {
    FirebaseFirestore _firestore =  FirebaseFirestore.instance;

    setState(() {
      isLoading = true;
    });

    await _firestore.collection('users').where("email", isEqualTo: _search.text).get().then((value) {
      setState(() {
        print(value.docs[0].data()['name']);
        userMap = value.docs[0].data() ;
        isLoading = false;
      });
      print(userMap);
    });

    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  FindingScreen(userMap: userMap,)));
  }

  String chatRoomId(String user1, String user2){
    if(user1[0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
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
                      Container(
                        padding: EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.pink[50],
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.add, color :Colors.pink, size: 20,),
                            SizedBox(width: 2,),
                            Text(
                              "Add friend",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            )
                          ],
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
                onSubmitted: (value){
                  onSearch();
                },
              ),
            ),
            SizedBox(height: 20,),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,color: Color(0xFFe9eaec),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 33,
                            ),
                          ),
                        ),
                        SizedBox(height: 10,),
                        SizedBox(
                          width: 75,
                          child: Align(
                            child: Text(
                              'Your story',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ) ,
                  ),
                  Row(
                    children: List.generate(storyList.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 60,
                              height: 60,
                              child: Stack(
                                children: <Widget>[
                                  storyList[index]['hasStory']
                                    ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blueAccent,width: 3
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(3.0),
                                        child: Container(
                                          width: 75,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: AssetImage(
                                                storyList[index]['imageUrl']
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                  )
                                      : Container(
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: AssetImage(
                                          storyList[index]['imageUrl'],
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    ),
                                  ),
                                  storyList[index]['isOnline']
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
                                                  image: AssetImage(
                                                      storyList[index]['imageUrl']),
                                                  fit: BoxFit.cover)),
                                  ),
                                  storyList[index]['isOnline']
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
                                                  color: Color(0xFFFFFFFF), width: 3)),
                                        ),
                                  )
                                      : Container(
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
                                  storyList[index]['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            // ListView.builder(
            //   itemCount: numberOfConversation(),
            //   shrinkWrap: true,
            //   padding: EdgeInsets.only(top: 16),
            //   physics: NeverScrollableScrollPhysics(),
            //   itemBuilder: (context, index){
            //     return ConversationList(
            //       name: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').doc('chatHistory')['name'],
            //       messageText: chatUsers[index].messageText,
            //       imageUrl: chatUsers[index].imageURL,
            //       time: chatUsers[index].time,
            //       isMessageRead: (index == 0 || index == 3)?true:false,
            //     );
            //   },
            // ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded),
            label: "Message",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.group),
            label: "Group",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_rounded),
            label: "Friend list",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
            label: "Setting",
          ),
      ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ListConversation {
  late String lastMessage;
  late String name;
  late String type;

  ListConversation({required this.lastMessage, required this.name, required this.type})

  factory ListConversation.fromJson(Map<String, dynamic> json) {
    return ListConversation(
      lastMessage: json['lastMessage'],
      name: json['name'],
      type : json['type'],
    );
  }

}

class ListConversationProvider extends ChangeNotifier {

  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ListConversation>> GetData() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get();
    List _conversation = snapshot.docs.map((d) => ListConversation(lastMessage: '', name: '', type: '').fromJson(d.data())).toList();
    return _conversation;
  }
}


