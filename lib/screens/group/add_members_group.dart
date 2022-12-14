// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../resources/methods.dart';

class AddMemberInGroup extends StatefulWidget {
  User user;

  final String groupName, groupId;
  final List membersList;

  AddMemberInGroup({Key? key, required this.groupName, required this.groupId, required this.membersList,required this.user}) : super(key: key);

  @override
  State<AddMemberInGroup> createState() => _AddMemberInGroupState();
}

class _AddMemberInGroupState extends State<AddMemberInGroup> {

  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String query = "";
  List membersList = [];

  @override
  void initState() {
    super.initState();
    membersList = widget.membersList;
  }


  void onAddMembers(Map<String, dynamic> map) async {

    membersList.add({
      "name" : map['name'],
      "email" : map['email'],
      "uid" : map['uid'],
      "isAdmin" : false,
      'avatar' : map['avatar'],
    });

    await _firestore.collection('groups').doc(widget.groupId).update({
      "members" : membersList,
    });

    await _firestore.collection('groups').doc(widget.groupId).collection('chats').add({
      "message" : "${widget.user.displayName} added ${map['name']}",
      "type": "notify",
      "time" : timeForMessage(DateTime.now().toString()),
      'timeStamp' : DateTime.now(),
    });

    await _firestore.collection('users').doc(map['uid']).collection('groups').doc(widget.groupId).set({
      "name" : widget.groupName,
      "id" : widget.groupId,
      'members' : membersList,
    });

    await _firestore.collection('users').doc(map['uid']).collection('chatHistory').doc(widget.groupId).set({
      'lastMessage' : "${widget.user.displayName} added ${map['name']}",
      'type' : "notify",
      'name' : widget.groupName,
      'time' : timeForMessage(DateTime.now().toString()),
      'uid' : widget.groupId,
      'avatar' : "https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98",
      'status' : "Online",
      'datatype' : "group",
      'timeStamp' : DateTime.now(),
      'isRead' : false,
    });
    await _firestore.collection('users').doc(map['uid']).collection('location').doc(widget.groupId).set({
      'isLocationed' : false,
    });
    for(int i = 0 ; i < membersList.length ; i++) {
      await _firestore.collection('users').doc(membersList[i]['uid']).collection('chatHistory').doc(widget.groupId).update({
        'lastMessage' : "${widget.user.displayName} added ${map['name']}",
        'type' : "notify",
        'time' : timeForMessage(DateTime.now().toString()),
        'timeStamp' : DateTime.now(),
        'isRead' : false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return isLoading ? Container(
      height: size.height,
      width: size.width,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    ) : GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey,
          title: const Text(
            "Add Members",
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
                  child: TextField(
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
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10,),
                onResultTap(query),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget onResultTap(String query) {
    FirebaseAuth _auth = FirebaseAuth.instance;
    return Expanded(
      child: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('uid' , isNotEqualTo: _auth.currentUser!.uid).snapshots(),
            builder: (context, snapshots){
              return (snapshots.connectionState == ConnectionState.waiting)
                  ? const Center(
                child: CircularProgressIndicator(),
              ) : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshots.data!.docs.length,
                  itemBuilder: (context, index) {
                    var map = snapshots.data!.docs[index].data() as Map<String, dynamic>;
                    if(query.isEmpty) {
                      return Container();
                    }
                    if(map['name'].toString().contains(query.toLowerCase()) || map['email'].toString().contains(query.toLowerCase())){
                      return ListTile(
                        onTap: () async {
                          setState(() {
                            isLoading = true;
                          });
                          onAddMembers(map);
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.pop(context);
                        },
                        title: Text(
                          map['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          map['email'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(map['avatar']),
                        ),
                        trailing: const Icon(Icons.add),
                      );
                    }
                    return Container();
                  }
              );
            }
        ),
      ),
    );
  }
}
