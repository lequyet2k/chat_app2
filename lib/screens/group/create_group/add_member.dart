// import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/group/create_group/create_group.dart';

class AddMember extends StatefulWidget {
  User user;
  AddMember({Key? key, required this.user}) : super(key: key);

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {

  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> memberList = [] ;
  bool isLoading = false;
  Map<String, dynamic>? userMap;

  FirebaseFirestore _firestore =  FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUserDetail();
  }

  void getCurrentUserDetail() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((map) {
      setState(() {
        memberList.add({
          "name" : map['name'],
          "email" : map['email'],
          "uid" : map['uid'],
          "isAdmin" : true,
          "avatar" : map['avatar'],
        });
      });
    });
  }

  void onSearch() async {

    setState(() {
      isLoading = true;
    });

    await _firestore.collection('users').where("email", isEqualTo: _search.text).get().then((value) {
      setState(() {
        userMap = value.docs[0].data() ;
        isLoading = false;
      });
    });
    _search.clear();
  }

  void onResultTap() {

    bool isAlreadyExist = false;

    for(int i = 0 ; i < memberList.length ; i++) {
      if(memberList[i]['uid'] == userMap!['uid']) {
        isAlreadyExist = true;
      }
    }
    if(!isAlreadyExist) {
      setState(() {
        memberList.add({
          'name' : userMap!['name'],
          'email' : userMap!['email'],
          'uid' : userMap!['uid'],
          'isAdmin' : false,
          'avatar' : userMap!['avatar'],
        });
        userMap = null;
      });
    }
  }

  void removeMember(int index) {
    if(memberList[index]['uid'] != _auth.currentUser!.uid){
      setState(() {
        memberList.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Add Members",
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.only(top: 16, right: 16, left: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search..",
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
                controller: _search,
                onSubmitted: (value){
                  onSearch();
                },
              ),
            ),
            SizedBox(height: 10,),
            Flexible(
              child: ListView.builder(
                itemCount: memberList.length,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: (){
                      removeMember(index);
                    },
                    leading: Icon(Icons.account_circle),
                    title: Text(
                      memberList[index]['name'],
                      style: TextStyle(
                      ),
                    ),
                    subtitle: Text(memberList[index]['email']),
                    trailing: Icon(Icons.close),
                  );
                },
              ),
            ),
            userMap != null? ListTile(
              onTap: (){
                onResultTap();
              },
              leading: Icon(Icons.account_circle),
              title: Text(userMap!['name']),
              subtitle: Text(userMap!['email']),
              trailing: Icon(Icons.add),
            ) : SizedBox(),
          ],
        ),
      ),
      floatingActionButton: memberList.length >= 2 ? FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.forward),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateGroup(memberList: memberList,user: widget.user,)),
          );
        },
      ) : SizedBox(),
    );
  }
}
