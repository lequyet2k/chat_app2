import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/auth_screen.dart';
import 'package:my_porject/login_screen.dart';


class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {

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
    return Container(
      child: ElevatedButton(
        onPressed: () {
          logOuttt();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          );
        },
        child: Text("Log out"),
      ),
    );
  }
}
