import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<User?> createAccount(String name, String email, String password) async {
  FirebaseAuth _auth =  FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try{
    User? user =  (await _auth.createUserWithEmailAndPassword(email: email, password: password))
        .user;
    if(user != null) {
      print("Account created Succesfull");

      user.updateDisplayName(name);

      await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
        "name" :  name,
        "email" : email,
        "status" : "Unavalible",
        "uid" : _auth.currentUser!.uid,
      });

      return user;
    } else {
      print("Account creation failed");
      return user;
    }
  }catch(e) {
    print(e);
    return null;
  }
}

Future<User?> logIn(String email, String password ) async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try{
    User? user = (await _auth.signInWithEmailAndPassword(
        email: email, password: password)).user;

    if(user != null) {
      print("Login Sucessfull");

      return user;
    } else {
      print("Login Failed");
      return user;
    }
  } catch(e) {
    print(e);
    return null;
  }
}

Future logOut() async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try{
    await _auth.signOut();

  } catch(e) {
    print("error");
  }
}