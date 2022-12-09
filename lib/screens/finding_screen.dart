import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/chat_screen.dart';


class FindingScreen extends StatefulWidget {
  Map<String, dynamic> userMap;
  FindingScreen({required this.userMap});

  @override
  State<FindingScreen> createState() => _FindingScreenState();
}

class _FindingScreenState extends State<FindingScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String user1Name;

  String chatRoomId(String user1, String user2){
    if(user1[0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.userMap != null
          ? ListTile(
            onTap: () async {
              await _firestore.collection('users').where("email", isEqualTo: _auth.currentUser?.email).get().then((value) {
                setState(() {
                  user1Name = value.docs[0].get("name");
                });
              });
              String roomId = chatRoomId(user1Name,widget.userMap['name']);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: roomId, userMap: widget.userMap,currentUserName: user1Name,))
              );
            },
            leading: Icon(Icons.account_box),
            title: Text(widget.userMap['name']),
            subtitle: Text(widget.userMap['email']),
            trailing: Icon(Icons.chat),
      ) : Container(),
    );
  }
}

class CustomSearch extends SearchDelegate {
  List<String> allData = ['Viet Nam', 'America', 'Russia' , 'Germany', 'Italy'];

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
    List<String> matchQuery = [];
    for(var item in allData){
      if(item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
        itemBuilder: (context, index){
          var result = matchQuery[index];
          return ListTile(
            title: Text(result),
          );
        },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for(var item in allData){
      if(item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index){
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
    );
  }
  
}
