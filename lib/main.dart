import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/auth_screen.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_porject/resources/firebase_options.dart';
import 'package:provider/provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true);
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080, sslEnabled: false);
  runApp(const MyApp());
}

class  MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: "",
        debugShowCheckedModeBanner: false ,
        home: FutureBuilder(
          future: getCurrentUser(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if(snapshot.hasData) {
              return HomeScreen(user: snapshot.data);
            } else {
              return Login();
            }
          },
        ),
      ),
    );
  }
}

