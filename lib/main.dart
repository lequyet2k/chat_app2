import 'package:flutter/material.dart';
import 'package:my_porject/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_porject/firebase_options.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080, sslEnabled: false);
  runApp(MyApp());
}

class  MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "",
      debugShowCheckedModeBanner: false ,
      home: WelcomeScreen(),
    );
  }
}

