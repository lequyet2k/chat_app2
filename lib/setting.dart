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
  const Setting({super.key,});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth _auth = FirebaseAuth.instance;

  File? imageFile;

  bool isLoading = false;

  late Map<String, dynamic> userMap ;

  // @override
  // void initState() {
  //   super.initState();
  // }

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

    String? currentUserName;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).get().then((value){
      currentUserName = value['name'];
    });

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
      print(imageUrl);
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

    logOut();
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      "status" : 'offline',
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Setting"),
      ),
      body: isLoading ? Container(
        height: size.height ,
        width: size.width ,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ) :
      Container(
        width: MediaQuery.of(context).size.width,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
          builder: (BuildContext context,AsyncSnapshot<DocumentSnapshot> snapshot) {
            if(snapshot.data != null) {
              Map<String, dynamic> map = snapshot.data?.data() as Map<String, dynamic>;
              return Column(
                //crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(map['avatar']),
                    ),
                  ),
                  Text(map['name']),
                  Text(map['email']),
                  Container(
                    child: ElevatedButton(
                      onPressed: (){
                        getImage();
                      },
                      child: Text("Change avatar"),
                    ),
                  ),
                  Container(
                    child: ElevatedButton(
                      onPressed: (){
                        logOuttt();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text("Log out"),
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
