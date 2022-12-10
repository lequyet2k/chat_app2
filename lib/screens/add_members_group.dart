import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group_chat.dart';

class AddMemberInGroup extends StatefulWidget {

  final String groupName, groupId,currentUserName;
  final List membersList;

  const AddMemberInGroup({Key? key, required this.groupName, required this.groupId, required this.membersList, required this.currentUserName}) : super(key: key);

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
        print(value.docs[0].data()['name']);
        userMap = value.docs[0].data() ;
        isLoading = false;
      });
      print(userMap);
    });

    _search.clear();
  }

  void onAddMembers() async {

    membersList.add({
      "name" : userMap!['name'],
      "email" : userMap!['email'],
      "uid" : userMap!['uid'],
      "isAdmin" : false,
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
    
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) =>  GroupChatHomeScreen()),
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
