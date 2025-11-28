import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/screens/group/add_members_group.dart';

import '../../resources/methods.dart';

// ignore: must_be_immutable
class GroupInfo extends StatefulWidget {
  User user;
  List memberListt;
  bool isDeviceConnected;
  final String groupName, groupId;

  GroupInfo(
      {Key? key,
      required this.groupName,
      required this.groupId,
      required this.user,
      required this.memberListt,
      required this.isDeviceConnected})
      : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List membersList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getGroupMembers();
  }

  bool checkAdmin() {
    bool isAdmin = false;

    membersList.forEach((element) {
      if (element['uid'] == _auth.currentUser!.uid) {
        isAdmin = element['isAdmin'];
      }
    });

    return isAdmin;
  }

  void getGroupMembers() async {
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .get()
        .then((value) {
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
            title: const Text("Remove this member"),
          ),
        );
      },
    );
  }

  void removeMember(int index) async {
    if (checkAdmin()) {
      if (_auth.currentUser!.uid != membersList[index]['uid']) {
        setState(() {
          isLoading = true;
        });

        await _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('chats')
            .add({
          "message":
              "${widget.user.displayName} removed ${membersList[index]['name']}",
          "type": "notify",
          "time": timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
        await _firestore
            .collection('users')
            .doc(membersList[index]['uid'])
            .collection('groups')
            .doc(widget.groupId)
            .delete();
        await _firestore
            .collection('users')
            .doc(widget.user.uid)
            .collection('chatHistory')
            .doc(widget.groupId)
            .update({
          'lastMessage': "Bạn removed ${membersList[index]['name']}",
          'type': "notify",
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
          'isRead': true,
        });

        for (int i = 1; i < membersList.length; i++) {
          await _firestore
              .collection('users')
              .doc(membersList[i]['uid'])
              .collection('chatHistory')
              .doc(widget.groupId)
              .update({
            'lastMessage':
                "${widget.user.displayName} removed ${membersList[index]['name']}",
            'type': "notify",
            'time': timeForMessage(DateTime.now().toString()),
            'timeStamp': DateTime.now(),
            'isRead': false,
          });
        }
        await _firestore
            .collection('users')
            .doc(membersList[index]['uid'])
            .collection('chatHistory')
            .doc(widget.groupId)
            .delete();
        membersList.removeAt(index);

        await _firestore.collection('groups').doc(widget.groupId).update({
          "members": membersList,
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
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      String uid = _auth.currentUser!.uid;

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('chats')
          .add({
        "message": "${widget.user.displayName} has left the group",
        "type": "notify",
        "time": timeForMessage(DateTime.now().toString()),
        'timeStamp': DateTime.now(),
      });
      for (int i = 0; i < membersList.length; i++) {
        await _firestore
            .collection('users')
            .doc(membersList[i]['uid'])
            .collection('chatHistory')
            .doc(widget.groupId)
            .update({
          'lastMessage': "${widget.user.displayName} has left the group",
          'type': "notify",
          'time': timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
          'isRead': false,
        });
      }
      for (int i = 0; i < membersList.length; i++) {
        if (membersList[i]['uid'] == uid) {
          membersList.removeAt(i);
        }
      }

      await _firestore.collection('groups').doc(widget.groupId).update({
        "members": membersList,
      });
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(widget.groupId)
          .delete();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatHistory')
          .doc(widget.groupId)
          .delete();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(
                  user: widget.user,
                )),
      );
    } else {
      print("Cant leave group!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 2,
        shadowColor: Colors.black.withAlpha(76),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[100], size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Group Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[100],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.grey[900]))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Group Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Group Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: const CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              "https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98",
                            ),
                            radius: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Group Name
                        Text(
                          widget.groupName.length >= 25
                              ? '${widget.groupName.substring(0, 25)}...'
                              : widget.groupName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Member Count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${membersList.length} Members',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add Member Button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        if (widget.isDeviceConnected == false) {
                          showDialogInternetCheck();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMemberInGroup(
                                groupName: widget.groupName,
                                groupId: widget.groupId,
                                membersList: membersList,
                                user: widget.user,
                              ),
                            ),
                          );
                        }
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add_outlined, color: Colors.blue[700], size: 22),
                      ),
                      title: Text(
                        'Add Member',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[900],
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ),
                  ),

                  // Members List Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Members',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        ListView.builder(
                          itemCount: membersList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isAdmin = membersList[index]['isAdmin'] ?? false;
                            bool isCurrentUser = membersList[index]['uid'] == _auth.currentUser!.uid;
                            
                            return ListTile(
                              onTap: () {
                                if (widget.isDeviceConnected == false) {
                                  showDialogInternetCheck();
                                } else if (checkAdmin() && !isCurrentUser) {
                                  showRemoveDialog(index);
                                }
                              },
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      membersList[index]['avatar'],
                                    ),
                                    radius: 22,
                                  ),
                                  if (isAdmin)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                membersList[index]['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[900],
                                ),
                              ),
                              subtitle: Text(
                                membersList[index]['email'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: isAdmin
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    )
                                  : (checkAdmin() && !isCurrentUser)
                                      ? Icon(Icons.more_vert, color: Colors.grey[400], size: 20)
                                      : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Leave Group Button
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        if (widget.isDeviceConnected == false) {
                          showDialogInternetCheck();
                        } else {
                          onLeaveGroup();
                        }
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.logout, color: Colors.red[700], size: 22),
                      ),
                      title: Text(
                        'Leave Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[700],
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
    );
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
              style: TextStyle(letterSpacing: 0.5, fontSize: 12),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'Cancel');
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(letterSpacing: 0.5, fontSize: 15),
                  ))
            ],
          ));
}
