import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group/group_chat_room.dart';
import 'package:uuid/uuid.dart';

import '../../../resources/methods.dart';

class CreateGroup extends StatefulWidget {
  User user;
  bool isDeviceConnected;
  final List<Map<String, dynamic>> memberList ;
  CreateGroup({Key? key, required this.memberList, required this.user, required this.isDeviceConnected}) : super(key: key);

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {

  final TextEditingController _groupName = TextEditingController();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }
  List<String> usersName = [];
  String makeGroupName() {
    for(int i = 0; i < widget.memberList.length; i++) {
      usersName.add(widget.memberList[i]['name']);
    }
    print(usersName.join(", "));
    return usersName.join(", ");
  }

  void createGroup(String groupName) async {
    setState(() {
      isLoading = true;
    });

    String groupId  = Uuid().v1();

    await _firestore.collection('groups').doc(groupId).set({
      "members" : widget.memberList,
      "id" : groupId,
    });

    for(int i = 0;  i < widget.memberList.length ; i++ ){
      String uid  = widget.memberList[i]['uid'];
      await _firestore.collection('users').doc(uid).collection('groups').doc(groupId).set({
        "name" : groupName,
        "id" : groupId,
        'members' : widget.memberList,
      });
    }

    await _firestore.collection('groups').doc(groupId).collection('chats').add({
      "message" : "${widget.user.displayName} Created This Group",
      "type" : "notify",
      "time" : timeForMessage(DateTime.now().toString()),
      'timeStamp' : DateTime.now(),
    });

    for(int i = 0 ; i < widget.memberList.length ; i++) {
      await _firestore.collection('users').doc(widget.memberList[i]['uid']).collection('chatHistory').doc(groupId).set({
        'lastMessage' : "${widget.user.displayName} Created This Group",
        'type' : "notify",
        'name' : groupName,
        'time' : timeForMessage(DateTime.now().toString()),
        'uid' : groupId,
        'avatar' : "https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98",
        'status' : "Online",
        'datatype' : "group",
        'timeStamp' : DateTime.now(),
        'isRead' : false,
      });
      await _firestore.collection('users').doc(widget.memberList[i]['uid']).collection('location').doc(groupId).set({
        'isLocationed' : false,
      });
    }

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => GroupChatRoom(groupChatId: groupId, groupName: groupName, user: widget.user, isDeviceConnected: widget.isDeviceConnected,)),
            (route) => false);
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
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
          SizedBox(height: 10,),
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
          SizedBox(height: 20,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
              onPressed: () {
              if(_groupName.text == ''){
                createGroup(makeGroupName());
              } else {
                createGroup(_groupName.text);
              }
              },
              child: const Text(
                "Create Group",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
          ),
        ],
      ),
    );
  }
}
