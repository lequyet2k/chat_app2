import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_porject/auth_screen.dart';
import 'package:my_porject/login_screen.dart';
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
        uId = value.docs[i]['uid'] ;
      });
      await _firestore.collection('users').doc(uId).collection('chatHistory').doc(_auth.currentUser!.uid).update({
        'status' : 'Offline',
      });
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Setting"),
      ),
      body: isLoading ? Container(
        height: size.height ,
        width: size.width ,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ) :
      Container(
        color: Colors.black87,
        width: MediaQuery.of(context).size.width,
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
                                    map['avatar'],
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
                      color: Colors.white
                    ),
                  ),
                  SizedBox(height: 20,),
                  Container(
                    margin: EdgeInsets.only(left: 20,right: 20),
                    height: size.height / 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
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
                                    fontWeight: FontWeight.bold,
                                  fontSize: 14
                                ),
                              ),
                              Spacer(),
                              Text(
                                map['name'],
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
                              IconButton(
                                onPressed: (){},
                                icon: Icon(Icons.highlight_off),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                  Container(
                    margin: EdgeInsets.only(left: 20,right: 20),
                    height: size.height / 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
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
                                "Notifications and sounds",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14
                                ),
                              ),
                              Spacer(),
                              IconButton(
                                onPressed: (){},
                                icon: Icon(Icons.create_outlined),
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
                  SizedBox(height: 20,),
                  GestureDetector(
                    onTap: () {
                      logOuttt();
                    },
                    child: Container(
                      padding: EdgeInsets.all(14),
                      height: size.height / 20,
                      width: size.width / 5,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Log Out",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
    );
  }
}
