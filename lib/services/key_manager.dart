import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';

/// Key Manager - Manages encryption keys for users
/// 
/// Functions:
/// - Generate and store user's RSA key pair
/// - Store public key in Firestore (for other users)
/// - Store private key securely on device
/// - Retrieve other users' public keys for encryption
class KeyManager {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Keys for secure storage
  static const String _publicKeyStorageKey = 'e2ee_public_key';
  static const String _privateKeyStorageKey = 'e2ee_private_key';
  
  /// Initialize encryption keys for current user
  /// Call this after user login/signup
  static Future<void> initializeKeys() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Check if keys already exist
      final privateKey = await _secureStorage.read(key: _privateKeyStorageKey);
      
      if (privateKey == null) {
        // Generate new key pair
        final keyPair = EncryptionService.generateRSAKeyPair();
        
        // Store private key securely on device
        await _secureStorage.write(
          key: _privateKeyStorageKey,
          value: keyPair['privateKey'],
        );
        
        await _secureStorage.write(
          key: _publicKeyStorageKey,
          value: keyPair['publicKey'],
        );
        
        // Upload public key to Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'publicKey': keyPair['publicKey'],
          'encryptionEnabled': true,
        });
        
        if (kDebugMode) {
          debugPrint('✅ E2EE Keys initialized for user: ${currentUser.uid}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('✅ E2EE Keys already exist for user');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing keys: $e');
      }
    }
  }
  
  /// Get current user's private key
  static Future<String?> getPrivateKey() async {
    try {
      return await _secureStorage.read(key: _privateKeyStorageKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting private key: $e');
      }
      return null;
    }
  }
  
  /// Get current user's public key
  static Future<String?> getPublicKey() async {
    try {
      return await _secureStorage.read(key: _publicKeyStorageKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting public key: $e');
      }
      return null;
    }
  }
  
  /// Get another user's public key from Firestore
  static Future<String?> getUserPublicKey(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['publicKey'] as String?;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user public key: $e');
      }
      return null;
    }
  }
  
  /// Check if user has encryption enabled
  static Future<bool> isEncryptionEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['encryptionEnabled'] == true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete all keys (for logout or account deletion)
  static Future<void> deleteKeys() async {
    try {
      await _secureStorage.delete(key: _privateKeyStorageKey);
      await _secureStorage.delete(key: _publicKeyStorageKey);
      
      if (kDebugMode) {
        debugPrint('✅ E2EE Keys deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting keys: $e');
      }
    }
  }
  
  /// Check if current user has keys initialized
  static Future<bool> hasKeys() async {
    try {
      final privateKey = await _secureStorage.read(key: _privateKeyStorageKey);
      return privateKey != null;
    } catch (e) {
      return false;
    }
  }
}
