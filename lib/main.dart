import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/resources/firebase_options.dart';
import 'package:my_porject/screens/login_screen.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/services/key_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'E2EE Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _keysInitialized = false;

  Future<void> _ensureEncryptionReady(User user) async {
    if (!_keysInitialized) {
      await KeyManager.ensureKeysReady();
      _keysInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, ensure encryption keys and show home screen
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: _ensureEncryptionReady(snapshot.data!),
            builder: (context, keySnapshot) {
              if (keySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing encryption...'),
                      ],
                    ),
                  ),
                );
              }
              return HomeScreen(user: snapshot.data!);
            },
          );
        }

        // Otherwise, show login screen
        return Login();
      },
    );
  }
}
