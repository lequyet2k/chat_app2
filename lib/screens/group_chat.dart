import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/chathome_screen.dart';
import 'package:my_porject/screens/group_chat_room.dart';
import 'package:my_porject/screens/create_group/add_member.dart';

class GroupChatHomeScreen extends StatefulWidget {
  const GroupChatHomeScreen({Key? key}) : super(key: key);

  @override
  State<GroupChatHomeScreen> createState() => _GroupChatHomeScreenState();
}

class _GroupChatHomeScreenState extends State<GroupChatHomeScreen> {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  late String currentUserName;

  List groupList = [];

  @override
  void initState() {
    super.initState();
    getGroup();
  }

  void getGroup() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('groups').get().then((value) {
      setState(() {
        groupList = value.docs;
        isLoading = false;
      });
    });
    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((value) {
      currentUserName = value['name'];
    }) ;
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Group"),
        actions: [
          IconButton(
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => HomeScreen()),
              // );
            },
            icon: Icon(Icons.more_vert),
          )
        ],
      ),
      body: isLoading ? Container(
        height: size.height,
        width: size.width,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ) :
      ListView.builder(
          itemCount: groupList.length,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupChatRoom(groupChatId: groupList[index]['id'], groupName: groupList[index]['name'], currentUserName: currentUserName,))
                );
              },
              leading: Icon(Icons.group),
              title: Text(
                  groupList[index]['name'],
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddMember())
          );
        },
        child: Icon(Icons.create),
        tooltip: "Create Group",
      ),
    );
  }
}
