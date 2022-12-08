import 'package:flutter/material.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_porject/resources/firebase_options.dart';
import 'package:provider/provider.dart';


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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: "",
        debugShowCheckedModeBanner: false ,
        home: WelcomeScreen(),
      ),
    );
  }
}

