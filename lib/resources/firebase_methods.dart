import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class FirebaseMethods {


  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // Future<FirebaseUser> getCurrentUser() async {
  //   FirebaseUser currentUser;
  //   Firebas
  //   currentUser = await _auth.currentUser;
  //   return currentUser;
  //   return _auth.currentUser;
  // }

  Future<Userr> getUserDetails() async {
    User? currentUser = _auth.currentUser;

    final documentSnapshot =
    await _firestore.collection('users').doc(currentUser!.uid).get();

    print(documentSnapshot.data());

    return Userr.fromMap(documentSnapshot.data()!);


  }
}

