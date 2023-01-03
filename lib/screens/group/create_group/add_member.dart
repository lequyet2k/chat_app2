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
  // Map<String, dynamic>? userMap;
  String query = "";

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

    // setState(() {
    //   isLoading = true;
    // });
    //
    // await _firestore.collection('users').where("email", isEqualTo: _search.text).get().then((value) {
    //   setState(() {
    //     userMap = value.docs[0].data() ;
    //     isLoading = false;
    //   });
    // });
    // _search.clear();
  }

  void addMemberToList(Map<String, dynamic> userMap) async {
    bool isAlreadyExist = false;

    for(int i = 0 ; i < memberList.length ; i++) {
      if(memberList[i]['uid'] == userMap['uid']) {
        isAlreadyExist = true;
      }
    }
    if(!isAlreadyExist) {
      setState(() {
        memberList.add({
          'name' : userMap['name'],
          'email' : userMap['email'],
          'uid' : userMap['uid'],
          'isAdmin' : false,
          'avatar' : userMap['avatar'],
        });
      });
    }
  }

  Widget onResultTap(String query) {
    return Expanded(
      child: SingleChildScrollView(
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
                      onTap: () async {
                        addMemberToList(map);
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
                      trailing: Icon(Icons.add),
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

  void removeMember(int index) async {
    if(memberList[index]['uid'] != _auth.currentUser!.uid){
      await _firestore.collection("users").doc(memberList[index]['uid']).update({
        'isTap' : false,
      });
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              // controller: _search,
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          SizedBox(height: 25,),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                  memberList.length,
                  (index) {
                    return GestureDetector(
                      onTap: (){
                        removeMember(index,);
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 10, right: 15),
                        child: Column(
                          children: [
                            Container(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            memberList[index]['avatar'] ?? widget.user.photoURL,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                    ),
                                  ),
                                  Positioned(
                                    left: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade500,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade500,
                                            width: 2,
                                          )
                                      ),
                                      child: memberList[index]['uid'] == _auth.currentUser!.uid ? Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 13.5,
                                      ) : Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 13.5,
                                      )
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 5,),
                            Text(memberList[index]['name']),
                          ],
                        ),
                      ),
                    );
                  }
              ),
            ),
          ),
          Container(
            height: 5,
            // decoration: const BoxDecoration(
            //     border: Border(
            //         bottom: BorderSide(
            //           color: Colors.grey,
            //           width: 0.5,
            //         )
            //     )
            // ),
          ),
          onResultTap(query),
        ],
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
