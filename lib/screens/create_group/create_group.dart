import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:my_porject/screens/group_chat.dart';

class CreateGroup extends StatefulWidget {
  final List<Map<String, dynamic>> memberList ;
  const CreateGroup({Key? key, required this.memberList}) : super(key: key);

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {

  final TextEditingController _groupName = TextEditingController();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserName;

  void createGroup() async {

    setState(() {
      isLoading = true;
    });

    String groupId  = Uuid().v1();
    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((value) {
      currentUserName = value['name'];
    }) ;

    await _firestore.collection('groups').doc(groupId).set({
      "members" : widget.memberList,
      "id" : groupId,
    });

    for(int i = 0;  i < widget.memberList.length ; i++ ){
      String uid  = widget.memberList[i]['uid'];
      await _firestore.collection('users').doc(uid).collection('groups').doc(groupId).set({
        "name" : _groupName.text,
        "id" : groupId,
      });
    }

    await _firestore.collection('groups').doc(groupId).collection('chats').add({
      "message" : " $currentUserName Created This Group",
      "type" : "notify",
      "time" : DateTime.now(),
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => GroupChatHomeScreen()),
            (route) => false);
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Group Name",
        ),
      ),
      body: isLoading ? Container(
        height: size.height ,
        width: size.width ,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ) :
      Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 16, right: 16, left: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Enter group name...",
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
              controller: _groupName,
              onSubmitted: (value){
              },
            ),
          ),
          ElevatedButton(
              onPressed: () {
                createGroup();
              },
              child: Text("Create Group"),
          ),
        ],
      ),
    );
  }
}
