import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Google Sign In 7.x: Use GoogleSignIn.instance.authenticate() API
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_porject/services/key_manager.dart';

Future<User?> createAccount(String name, String email, String password) async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    UserCredential? userCredential = (await _auth
        .createUserWithEmailAndPassword(email: email, password: password));
    print("Account created Succesfull");
    await userCredential.user!.updateDisplayName(name);
    await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
      "name": name,
      "email": email,
      "status": "Online",
      "uid": _auth.currentUser!.uid,
      "avatar":
          "https://firebasestorage.googleapis.com/v0/b/chatapptest2-93793.appspot.com/o/images%2F5c1b8830-75fc-11ed-a92f-3d766ba9d8a3.jpg?alt=media&token=6160aa31-424d-42f6-871e-0ca425e937cb",
    });

    // Initialize encryption keys for new user
    await KeyManager.initializeKeys();
    print("✅ Encryption keys initialized");

    return userCredential.user;
  } catch (e) {
    print(e);
    return null;
  }
}

Future<User?> logIn(String email, String password) async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    User? user = (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((value) {
      user?.updateDisplayName(value['name']);
    });

    if (user != null) {
      print("Login Successful");

      // Initialize encryption keys if not already present
      await KeyManager.initializeKeys();
      print("✅ Encryption keys ready");

      return user;
    } else {
      print("Login Failed");
      return user;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Future logOut() async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  try {
    // Google Sign In 7.x API - use static instance
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  } catch (e) {
    print("error");
  }
}

Future<User?> signInWithGoogle() async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    // Google Sign In 7.x API - initialize and authenticate
    await GoogleSignIn.instance.initialize();
    
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // User cancelled or error occurred
      print('Google Sign In cancelled or failed: $e');
      return null;
    }

    // Get authorization tokens for Firebase
    final GoogleSignInClientAuthorization? auth = 
        await googleUser.authorizationClient.authorizationForScopes([]);
    
    if (auth == null) {
      print('Failed to get authorization tokens');
      return null;
    }

    // Get authentication tokens (idToken from authentication getter)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      print('Failed to get ID token');
      return null;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: idToken,
    );

    await _auth.signInWithCredential(credential);
    User? user = (await _auth.signInWithCredential(credential)).user;
    if (user != null) {
      await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
        "name": googleUser.displayName,
        "email": googleUser.email,
        "status": "Online",
        "uid": _auth.currentUser!.uid,
        "avatar": googleUser.photoUrl,
      });

      // Initialize encryption keys
      await KeyManager.initializeKeys();
      print("✅ Encryption keys initialized");

      print("Login Successful");
      return user;
    } else {
      print("Login Failed");
      return user;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Future<User?> signInWithFacebook() async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final LoginResult loginResult = await FacebookAuth.instance
      .login(permissions: ['email', 'public_profile']);

  if (loginResult == LoginStatus.success) {
    final OAuthCredential oAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    User? user =
        (await FirebaseAuth.instance.signInWithCredential(oAuthCredential))
            .user;

    if (user != null) {
      await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
        "name": user.displayName,
        "email": user.email,
        "status": "Online",
        "uid": _auth.currentUser!.uid,
        "avatar": user.photoURL,
      });

      // Initialize encryption keys
      await KeyManager.initializeKeys();
      print("✅ Encryption keys initialized");

      print("Login Successful");
      return user;
    } else {
      print("Login Failed");
      return user;
    }
  } else {
    print(loginResult.message);
  }
  return null;
}

Future<User?> getCurrentUser() async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  User? currentUser;
  currentUser = _auth.currentUser;
  return currentUser;
}
