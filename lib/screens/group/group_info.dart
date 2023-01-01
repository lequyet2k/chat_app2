import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group/add_members_group.dart';

import '../../resources/methods.dart';
import 'group_chat.dart';

class GroupInfo extends StatefulWidget {

  User user;
  List memberListt;
  final String groupName, groupId;

  GroupInfo({Key? key, required this.groupName, required this.groupId,required this.user, required this.memberListt}) : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List membersList = [] ;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getGroupMembers();
  }

  bool checkAdmin() {
    bool isAdmin = false;
    
    membersList.forEach((element) {
      if(element['uid'] == _auth.currentUser!.uid) {
        isAdmin = element['isAdmin'];
      }
    });

    return isAdmin;
  }

  void getGroupMembers() async {
    await _firestore.collection('groups').doc(widget.groupId).get().then((value) {
      setState(() {
        membersList = value['members'];
        isLoading = false;
      });
    });
  }

  void showRemoveDialog(int index) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: ListTile(
              onTap: () {
                removeMember(index);
                Navigator.pop(context);
              },
              title: Text("Remove this member"),
            ),
          );
        },
    );
  }

  void removeMember(int index) async {

    if(checkAdmin()) {
      if(_auth.currentUser!.uid != membersList[index]['uid']){
        setState(() {
          isLoading = true;
        });

        await _firestore.collection('groups').doc(widget.groupId).collection('chats').add({
          "message" : "${widget.user.displayName} removed ${membersList[index]['name']}",
          "type": "notify",
          "time" : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
        await _firestore.collection('users').doc(membersList[index]['uid']).collection('groups').doc(widget.groupId).delete();
        await _firestore.collection('users').doc(widget.user.uid).collection('chatHistory').doc(widget.groupId).update({
          'lastMessage' : "Bạn removed ${membersList[index]['name']}",
          'type' : "notify",
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });

        for(int i = 1 ; i < membersList.length ; i++) {
          await _firestore.collection('users').doc(membersList[i]['uid']).collection('chatHistory').doc(widget.groupId).update({
            'lastMessage' : "${widget.user.displayName} removed ${membersList[index]['name']}",
            'type' : "notify",
            'time' : timeForMessage(DateTime.now().toString()),
            'timeStamp' : DateTime.now(),
          });
        }
        membersList.removeAt(index);

        await _firestore.collection('groups').doc(widget.groupId).update({
          "members" : membersList,
        });
        // await _firestore.collection('users').doc(uid).collection('chatHistory').doc(widget.groupId).delete();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print("Cant remove");
    }

  }

  void onLeaveGroup() async {

    if(!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      String uid = _auth.currentUser!.uid;

      await _firestore.collection('groups').doc(widget.groupId).collection('chats').add({
        "message" : "${widget.user.displayName} has left the group",
        "type": "notify",
        "time" : timeForMessage(DateTime.now().toString()),
        'timeStamp' : DateTime.now(),
      });
      for(int i = 0 ; i < membersList.length ; i++) {
        await _firestore.collection('users').doc(membersList[i]['uid']).collection('chatHistory').doc(widget.groupId).update({
          'lastMessage' : "${widget.user.displayName} has left the group",
          'type' : "notify",
          'time' : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
      }
      for(int i = 0 ; i < membersList.length ; i++) {
        if(membersList[i]['uid'] == uid){
          membersList.removeAt(i);
        }
      }

      await _firestore.collection('groups').doc(widget.groupId).update({
        "members" : membersList,
      });
      await _firestore.collection('users').doc(uid).collection('groups').doc(widget.groupId).delete();
      await _firestore.collection('users').doc(uid).collection('chatHistory').doc(widget.groupId).delete();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupChatHomeScreen(user: widget.user,)),
      );
    }else {
      print("Cant leave group!");
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: isLoading ? Container(
          height: size.height,
          width: size.width,
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ) : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackButton(),
              ),
              Container(
                height: size.height / 8,
                width: size.width / 1.1,
                child: Row(
                  children: [
                    Container(
                      height: size.height / 5 ,
                      width: size.width / 5 ,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage("https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98"),
                        maxRadius: 30,
                      )
                    ),
                    SizedBox(
                      width: 20 ,
                    ),
                    Container(
                      child: widget.groupName.length >= 17
                          ? Text(
                          '${widget.groupName.substring(0, 17)}...',
                          style: TextStyle(
                              fontSize: size.width / 16,fontWeight: FontWeight.w500)
                      )
                          : Text(widget.groupName, style: TextStyle(
                          fontSize: size.width / 16,fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              Container(
                width: size.width / 1.1,
                child: Text(
                  " ${membersList.length} Members",
                  style: TextStyle(
                    fontSize: size.width / 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 10,),
              ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddMemberInGroup(groupName: widget.groupName, groupId: widget.groupId, membersList: membersList,user: widget.user,)),
                  );
                },
                leading: Icon(
                  Icons.add,
                ),
                title: Text(
                  "Add member",
                  style: TextStyle(
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Flexible(
                  child: ListView.builder(
                    itemCount: membersList.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          showRemoveDialog(index);
                        },
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(membersList[index]['avatar']),
                          maxRadius: 20,
                        ),
                        title: Text(
                          membersList[index]['name'],
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(membersList[index]['email']),
                        trailing: Text(membersList[index]['isAdmin'] ? "Admin" : ""),
                      );
                    },
                  )
              ),
              SizedBox(height: 5,),
              ListTile(
                onTap: () {
                  onLeaveGroup();
                },
                leading: Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                title: Text(
                    "Leave Group",
                  style: TextStyle(
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
