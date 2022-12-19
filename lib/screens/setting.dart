import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_porject/screens/auth_screen.dart';
import 'package:my_porject/screens/login_screen.dart';
import 'package:uuid/uuid.dart';


class Setting extends StatefulWidget {

  User user;

  Setting({super.key,required this.user});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth _auth = FirebaseAuth.instance;

  File? imageFile;

  bool isLoading = false;

  late Map<String, dynamic> userMap ;

  bool isSwitched = false;
  bool isSwitched2 = false;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if(xFile != null){
        imageFile = File(xFile.path as String);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {

    setState(() {
      isLoading = true;
    });

    String fileName = Uuid().v1();

    int status = 1;


    var ref = FirebaseStorage.instance.ref().child('images').child(
        "$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      // await _firestore.collection('chatroom').doc(widget.chatRoomId).collection(
      //     'chats').doc(fileName).delete();
      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'avatar': imageUrl,
      });
      int? n;
      await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value) => {
        n = value.docs.length
      });
      for(int i = 0 ; i < n! ; i++) {
        String? uId;
        await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value){
          uId = value.docs[i]['uid'] ;
        });
        await _firestore.collection('users').doc(uId).collection('chatHistory').doc(_auth.currentUser!.uid).update({
          'avatar' : imageUrl,
        });
      }
    }
    print(imageFile);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> logOuttt() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    FirebaseAuth _auth = FirebaseAuth.instance;

    setState(() {
      isLoading = true;
    });

    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status" : 'Offline',
    });

    int? n;
    await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value) => {
      n = value.docs.length
    });
    for(int i = 0 ; i < n! ; i++) {
      String? uId;
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatHistory').get().then((value){
        // if(value.docs[i]['datatype'] == 'p2p'){
        //   uId = value.docs[i]['uid'] ;
        // }
        uId = value.docs[i]['uid'];
      });
      // await _firestore.collection('users').doc(uId).collection('chatHistory').doc(_auth.currentUser!.uid).update({
      //   'status' : 'Offline',
      // });
    }
    logOut();
    setState(() {
      isLoading = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading ? Container(
        height: size.height ,
        width: size.width ,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ) :
      Column(
        children: [
          SafeArea(
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(left: 16, top: 10, right: 16),
              child: Text(
                "Setting",
                style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(widget.user.uid.isNotEmpty ? widget.user.uid : "0").snapshots(),
              builder: (BuildContext context,AsyncSnapshot<DocumentSnapshot> snapshot) {
                if(snapshot.data != null) {
                  Map<String, dynamic> map = snapshot.data?.data() as Map<String, dynamic>;
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(height: 10,),
                      GestureDetector(
                        onTap: (){
                          getImage();
                        },
                        child: Container(
                          height: 100,
                          width: 100,
                          child: Stack(
                            children: [
                              Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        map['avatar'] ?? widget.user.photoURL,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                ),
                              ),
                              Positioned(
                                top: 68,
                                left: 75,
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black87,
                                        width: 2,
                                      )
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 13.5,
                                  ),
                                ),
                              )
                            ]
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Text(
                        map['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black
                        ),
                      ),
                      SizedBox(height: 30,),
                      Container(
                        margin: EdgeInsets.only(left: 20,right: 20),
                        height: size.height / 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black38,
                                    )
                                  )
                              ),
                              height: size.height / 18,
                              child: Row(
                                children: [
                                  SizedBox(width: 5,),
                                  Icon(Icons.perm_identity),
                                  SizedBox(width: 7,),
                                  Text(
                                      "Name :",
                                    style: TextStyle(
                                      color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      fontSize: 14
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    map['name'],
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      fontSize: 14
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: (){},
                                      icon: Icon(Icons.create_outlined,
                                      ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                        color: Colors.black38,

                                      )
                                  )
                              ),
                              height: size.height / 18,
                              child: Row(
                                children: [
                                  SizedBox(width: 5,),
                                  Icon(Icons.email_outlined),
                                  SizedBox(width: 7,),
                                  Text(
                                    "Email :",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    map['email'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: (){},
                                    icon: Icon(Icons.create_outlined),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: size.height / 18,
                              child: Row(
                                children: [
                                  SizedBox(width: 5,),
                                  Icon(Icons.online_prediction),
                                  SizedBox(width: 7,),
                                  Text(
                                    "Status :",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    map['status'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  Switch(
                                    value: isSwitched,
                                    onChanged: (value) {
                                      setState(() {
                                        isSwitched = value;
                                        print(isSwitched);
                                      });
                                    },
                                    activeTrackColor: Colors.green,
                                    activeColor: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30,),
                      Container(
                        margin: EdgeInsets.only(left: 20,right: 20),
                        height: size.height / 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                        color: Colors.black38,
                                      )
                                  )
                              ),
                              height: size.height / 20,
                              child: Row(
                                children: [
                                  SizedBox(width: 5,),
                                  Icon(Icons.notifications_active_outlined),
                                  SizedBox(width: 7,),
                                  Text(
                                    "Notifications",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  Spacer(),
                                  Switch(
                                    value: isSwitched2,
                                    onChanged: (value) {
                                      setState(() {
                                        isSwitched2 = value;
                                        print(isSwitched2);
                                      });
                                    },
                                    activeTrackColor: Colors.green,
                                    activeColor: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: size.height / 20,
                              child: Row(
                                children: [
                                  SizedBox(width: 5,),
                                  Icon(Icons.help_outline),
                                  SizedBox(width: 7,),
                                  Text(
                                    "Help",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40,),
                      GestureDetector(
                        onTap: () {
                          logOuttt();
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 20,right: 20),
                          height: size.height / 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(width: 5,),
                                Icon(Icons.logout_outlined, color: Colors.redAccent,),
                                SizedBox(width: 7,),
                                Text(
                                  "Log Out",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container();
                }
              }
            ),
          ),
        ],
      ),
    );
  }
}