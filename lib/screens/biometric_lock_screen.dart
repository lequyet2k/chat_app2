import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';

/// Biometric Lock Screen
/// Shows when app launches if biometric authentication is enabled
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticationSuccess;

  const BiometricLockScreen({
    super.key,
    required this.onAuthenticationSuccess,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _isAuthenticating = false;
  String _errorMessage = '';
  List<BiometricType> _availableBiometrics = [];
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkBiometricAvailability();
    _authenticateUser();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  Future<void> _checkBiometricAvailability() async {
    final biometrics = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _availableBiometrics = biometrics;
      });
    }
  }

  Future<void> _authenticateUser() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final message = await _biometricService.getBiometricMessage();
      final authenticated = await _biometricService.authenticate(
        localizedReason: message,
        biometricOnly: false,
      );

      if (mounted) {
        if (authenticated) {
          widget.onAuthenticationSuccess();
        } else {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isAuthenticating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  String _getBiometricTitle() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face Recognition';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric Authentication';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble,
                    size: 60,
                    color: Colors.blue[400],
                  ),
                ),
                const SizedBox(height: 40),

                // App Name
                Text(
                  'Secure Chat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Private & Secure Messaging',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),

                // Biometric Icon (Animated)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getBiometricIcon(),
                          size: 80,
                          color: Colors.blue[300],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Biometric Type Title
                Text(
                  _getBiometricTitle(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Instruction Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _isAuthenticating
                        ? 'Please authenticate to unlock'
                        : 'Tap the button below to authenticate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Authenticate Button
                if (!_isAuthenticating)
                  ElevatedButton.icon(
                    onPressed: _authenticateUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(_getBiometricIcon(), size: 24),
                    label: const Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                // Loading Indicator
                if (_isAuthenticating)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[300]!,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authenticating...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 60),

                // Security Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.green[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'End-to-End Encrypted',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
