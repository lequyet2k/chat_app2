import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group/group_chat_room.dart';
import 'package:my_porject/screens/group/create_group/add_member.dart';


// ignore: must_be_immutable
class GroupChatHomeScreen extends StatefulWidget {
  User user;
  bool isDeviceConnected;
  GroupChatHomeScreen({Key? key, required this.user, required this.isDeviceConnected}) : super(key: key);

  @override
  State<GroupChatHomeScreen> createState() => _GroupChatHomeScreenState();
}

class _GroupChatHomeScreenState extends State<GroupChatHomeScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  List groupList = [];

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15,left: 15),
          child: const Text(
              'Groups',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: StreamBuilder(
                  stream: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('groups').snapshots(),
                  builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                    if(snapshot.data!= null){
                      return ListView.builder(
                          itemCount: snapshot.data?.docs.length,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 5),
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                            return listGroup(map : map, memberList: map['members'] ?? [] );
                          }
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
              Positioned(
                right: 20.0,
                bottom: 20.0,
                child: FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: () {
                    if(widget.isDeviceConnected == false) {
                      showDialogInternetCheck();
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddMember(user: widget.user, isDeviceConnected: widget.isDeviceConnected,))
                      );
                    }
                  },
                  tooltip: "Create Group",
                  child: const Icon(Icons.create),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget listGroup({required Map<String, dynamic> map, required List<dynamic> memberList}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupChatRoom(groupChatId: map['id'], groupName: map['name'], user: widget.user, isDeviceConnected: widget.isDeviceConnected,))
        );
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top : 10, bottom: 10),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              backgroundImage: CachedNetworkImageProvider("https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F2a2c7410-7b06-11ed-aa52-c50d48cba6ef.jpg?alt=media&token=1b11fc5a-2294-4db8-94bf-7bd083f54b98"),
              maxRadius: 30,
            ),
            const SizedBox(width: 16,),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Text(map['name'],style: TextStyle(fontSize: 16),),
                    map['name'].toString().length >= 30
                        ? Text(
                        '${map['name'].toString().substring(0, 30)}...',
                        style: const TextStyle(
                          fontSize: 16,
                        )
                    )
                        : Text(map['name'], style: const TextStyle(
                      fontSize: 16,
                    )
                    ),
                    const SizedBox(height: 6,),
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2.1,),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('groups').doc(map['id']).snapshots(),
                        builder: (BuildContext context,AsyncSnapshot<DocumentSnapshot> snapshots){
                          if(snapshots.hasData) {
                            List length = snapshots.data!['members'] ;
                            return Text('Members: ${length.length}', style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,)
                            );
                          } else{
                            return Container();
                          }
                        },
                        //fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          style: TextStyle(
              letterSpacing: 0.5,
              fontSize: 12
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text(
                'OK',
                style: TextStyle(
                    letterSpacing: 0.5,
                    fontSize: 15
                ),
              )
          )
        ],
      )
  );
}
