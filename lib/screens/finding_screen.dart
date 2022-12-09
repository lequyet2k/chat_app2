import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/chat_screen.dart';

class CustomSearch extends SearchDelegate {

  User user;
  CustomSearch({required this.user});

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String chatRoomId(String? user1, String user2){
    if(user1![0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

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

    late String user1Name;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshots){
        return (snapshots.connectionState == ConnectionState.waiting)
            ? Center(
          child: CircularProgressIndicator(),
        ) : ListView.builder(
            itemCount: snapshots.data!.docs.length,
            itemBuilder: (context, index) {
              var map = snapshots.data!.docs[index].data() as Map<String, dynamic>;
              if(query.isEmpty) {
                return Container();
              }
              if(map['name'].toString().contains(query.toLowerCase()) || map['email'].toString().contains(query.toLowerCase())){
                return ListTile(
                  onTap: () async {
                    String roomId = chatRoomId(user.displayName,map['name']);
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: roomId, userMap: map,user:  user,))
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
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshots){
        return (snapshots.connectionState == ConnectionState.waiting)
            ? Center(
          child: CircularProgressIndicator(),
        ) : ListView.builder(
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
                    String roomId = chatRoomId(user.displayName,map['name']);
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: roomId, userMap: map,user:  user,))
                    );
                  },
                );
              }
              return Container();
            }
        );
      },
    );
  }
  
}
