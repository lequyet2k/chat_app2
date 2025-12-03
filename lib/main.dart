import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_porject/resources/firebase_options.dart';
import 'package:my_porject/screens/login_screen.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/screens/biometric_lock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/services/key_manager.dart';
import 'package:my_porject/services/biometric_auth_service.dart';
import 'package:my_porject/services/user_presence_service.dart';
import 'package:my_porject/utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handler
  ErrorHandler.initialize();
  
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

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _keysInitialized = false;
  final BiometricAuthService _biometricService = BiometricAuthService();
  final UserPresenceService _presenceService = UserPresenceService();
  bool _needsBiometricAuth = false;
  bool _isCheckingBiometric = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricRequirement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Update user presence based on app lifecycle
      if (state == AppLifecycleState.resumed) {
        print('📱 [Lifecycle] App RESUMED - setting user ONLINE');
        _presenceService.setUserOnline();
        _checkBiometricRequirement();
      } else if (state == AppLifecycleState.paused) {
        print('📱 [Lifecycle] App PAUSED - setting user OFFLINE');
        _presenceService.setUserOffline();
      } else if (state == AppLifecycleState.inactive) {
        print('📱 [Lifecycle] App INACTIVE');
        // Don't change status for inactive (e.g., phone call)
      } else if (state == AppLifecycleState.detached) {
        print('📱 [Lifecycle] App DETACHED - setting user OFFLINE');
        _presenceService.setUserOffline();
      }
    }
  }

  Future<void> _checkBiometricRequirement() async {
    print('🔐 [Biometric] Checking biometric requirement...');
    
    // Skip biometric auth on web platform
    if (kIsWeb) {
      print('🌐 [Biometric] Web platform - skipping biometric');
      if (mounted) {
        setState(() {
          _needsBiometricAuth = false;
          _isCheckingBiometric = false;
        });
      }
      return;
    }
    
    print('📱 [Biometric] Mobile platform - checking authentication need');
    final needsAuth = await _biometricService.needsReAuthentication();
    print('${needsAuth ? "🔒" : "🔓"} [Biometric] Needs auth: $needsAuth');
    
    if (mounted) {
      setState(() {
        _needsBiometricAuth = needsAuth;
        _isCheckingBiometric = false;
      });
    }
  }

  Future<void> _ensureEncryptionReady(User user) async {
    if (!_keysInitialized) {
      await KeyManager.ensureKeysReady();
      _keysInitialized = true;
    }
  }

  void _onBiometricSuccess() {
    setState(() {
      _needsBiometricAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show biometric lock if needed
    if (_needsBiometricAuth && !_isCheckingBiometric) {
      return BiometricLockScreen(
        onAuthenticationSuccess: _onBiometricSuccess,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting || _isCheckingBiometric) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, ensure encryption keys and show home screen
        if (snapshot.hasData && snapshot.data != null) {
          // Set user online when authenticated
          _presenceService.setUserOnline();
          
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

        // If user logged out, set offline
        if (snapshot.hasData == false) {
          _presenceService.setUserOffline();
        }

        // Otherwise, show login screen
        return Login();
      },
    );
  }
}
