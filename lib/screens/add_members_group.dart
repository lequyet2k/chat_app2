import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group_chat.dart';

class AddMemberInGroup extends StatefulWidget {
  User user;

  final String groupName, groupId,currentUserName;
  final List membersList;

  AddMemberInGroup({Key? key, required this.groupName, required this.groupId, required this.membersList, required this.currentUserName,required this.user}) : super(key: key);

  @override
  State<AddMemberInGroup> createState() => _AddMemberInGroupState();
}

class _AddMemberInGroupState extends State<AddMemberInGroup> {

  Map<String, dynamic>? userMap;
  bool isLoading = false;
  TextEditingController _search = TextEditingController();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  List membersList = [];

  @override
  void initState() {
    super.initState();
    membersList = widget.membersList;
  }

  void onSearch() async {

    setState(() {
      isLoading = true;
    });

    await _firestore.collection('users').where("email", isEqualTo: _search.text).get().then((value) {
      setState(() {
        userMap = value.docs[0].data() ;
        isLoading = false;
      });
    });
    _search.clear();
  }

  void onAddMembers() async {

    membersList.add({
      "name" : userMap!['name'],
      "email" : userMap!['email'],
      "uid" : userMap!['uid'],
      "isAdmin" : false,
      'avatar' : userMap!['avatar'],
    });

    await _firestore.collection('groups').doc(widget.groupId).update({
      "members" : membersList,
    });

    await _firestore.collection('groups').doc(widget.groupId).collection('chats').add({
      "message" : "${widget.currentUserName} added ${userMap!['name']}",
      "type": "notify",
      "time" : DateTime.now(),
    });

    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('groups').doc(widget.groupId).set({
      "name" : widget.groupName,
      "id" : widget.groupId,
    });

    await _firestore.collection('users').doc(userMap!['uid']).collection('chatHistory').doc(widget.groupId).set({
      'lastMessage' : "${widget.currentUserName} added ${userMap!['name']}",
      'type' : "notify",
      'name' : widget.groupName,
      'time' : DateTime.now(),
      'uid' : widget.groupId,
      'avatar' : "https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98",
      'status' : "Online",
      'datatype' : "group",
    });
    for(int i = 1 ; i < membersList.length ; i++) {
      await _firestore.collection('users').doc(membersList[i]['uid']).collection('chatHistory').doc(widget.groupId).update({
        'lastMessage' : "${widget.currentUserName} added ${userMap!['name']}",
        'type' : "notify",
        'time' : DateTime.now(),
      });
    }
    
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) =>  GroupChatHomeScreen(user: widget.user,)),
            (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: Text(
          "Add Members",
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            SizedBox(height: 10,),
            userMap != null? ListTile(
              onTap: (){
                onAddMembers();
              },
              leading: Icon(Icons.account_circle),
              title: Text(userMap!['name']),
              subtitle: Text(userMap!['email']),
              trailing: Icon(Icons.add),
            ) : SizedBox(),
          ],
        ),
      ),
    );
  }
}
