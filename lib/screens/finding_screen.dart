import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/chat_screen.dart';
import 'package:my_porject/resources/methods.dart';

class CustomSearch extends SearchDelegate {

  User user;
  bool isDeviceConnected;
  CustomSearch({required this.user, required this.isDeviceConnected});

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: Icon(Icons.clear),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').where('uid', isNotEqualTo: _auth.currentUser!.uid).snapshots(),
        builder: (context, snapshots){
          return (snapshots.connectionState == ConnectionState.waiting)
              ? Center(
            child: CircularProgressIndicator(),
          ) : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshots.data!.docs.length,
              itemBuilder: (context, index) {
                var map = snapshots.data!.docs[index].data() as Map<String, dynamic>;
                if(query.isEmpty) {
                  return Container();
                }
                if(map['name'].toString().contains(query.toLowerCase()) || map['email'].toString().contains(query.toLowerCase())){
                  return ListTile(
                    onTap: () async {
                      String roomId = ChatRoomId().chatRoomId(user.displayName,map['name']);
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: roomId, userMap: map,user:  user, isDeviceConnected: isDeviceConnected,))
                      );
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
                  );
                }
                return Container();
              }
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').where('uid' , isNotEqualTo: _auth.currentUser!.uid).snapshots(),
        builder: (context, snapshots){
          return (snapshots.connectionState == ConnectionState.waiting)
              ? Center(
            child: CircularProgressIndicator(),
          ) : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshots.data!.docs.length,
              itemBuilder: (context, index) {
                var map = snapshots.data!.docs[index].data() as Map<String, dynamic>;
                if(query.isEmpty) {
                  return Container();
                }
                if(map['name'].toString().contains(query.toLowerCase()) || map['email'].toString().contains(query.toLowerCase())){
                  return ListTile(
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
                    onTap: () async {
                      String roomId = ChatRoomId().chatRoomId(_auth.currentUser!.displayName,map['name']);
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: roomId, userMap: map,user:  user, isDeviceConnected: isDeviceConnected,))
                      );
                    },
                  );
                }
                return Container();
              }
          );
        },
      ),
    );
  }
  
}
