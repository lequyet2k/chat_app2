import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
// Note: SharedPreferences not needed - using FlutterSecureStorage for all sensitive data

/// Service để quản lý Private Chats với mật khẩu bảo vệ
class PrivateChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Keys for storage
  static const String _privatePasswordKey = 'private_chat_password';
  static const String _privateChatIdsKey = 'private_chat_ids';
  static const String _lastAuthKey = 'private_chat_last_auth';
  
  // Session timeout (5 minutes)
  static const int _sessionTimeoutMinutes = 5;
  
  /// Check if user has set up Private Chat password
  static Future<bool> hasPassword() async {
    try {
      final password = await _secureStorage.read(key: _privatePasswordKey);
      return password != null && password.isNotEmpty;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error checking password: $e');
      return false;
    }
  }
  
  /// Set up new password for Private Chat
  static Future<bool> setPassword(String password) async {
    try {
      if (password.length < 4) {
        throw Exception('Password must be at least 4 characters');
      }
      
      // Hash password before storing
      final hashedPassword = _hashPassword(password);
      await _secureStorage.write(key: _privatePasswordKey, value: hashedPassword);
      
      debugPrint('✅ PrivateChatService: Password set successfully');
      return true;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error setting password: $e');
      return false;
    }
  }
  
  /// Verify password
  static Future<bool> verifyPassword(String password) async {
    try {
      final storedHash = await _secureStorage.read(key: _privatePasswordKey);
      if (storedHash == null) return false;
      
      final inputHash = _hashPassword(password);
      final isValid = storedHash == inputHash;
      
      if (isValid) {
        // Update last auth time for session management
        await _updateLastAuthTime();
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error verifying password: $e');
      return false;
    }
  }
  
  /// Change password
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final isOldValid = await verifyPassword(oldPassword);
      if (!isOldValid) {
        throw Exception('Current password is incorrect');
      }
      
      return await setPassword(newPassword);
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error changing password: $e');
      return false;
    }
  }
  
  /// Reset password (requires re-authentication)
  static Future<bool> resetPassword() async {
    try {
      await _secureStorage.delete(key: _privatePasswordKey);
      await _secureStorage.delete(key: _privateChatIdsKey);
      await _secureStorage.delete(key: _lastAuthKey);
      
      debugPrint('✅ PrivateChatService: Password reset successfully');
      return true;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error resetting password: $e');
      return false;
    }
  }
  
  /// Check if session is still valid
  static Future<bool> isSessionValid() async {
    try {
      final lastAuthStr = await _secureStorage.read(key: _lastAuthKey);
      if (lastAuthStr == null) return false;
      
      final lastAuth = DateTime.parse(lastAuthStr);
      final now = DateTime.now();
      final difference = now.difference(lastAuth).inMinutes;
      
      return difference < _sessionTimeoutMinutes;
    } catch (e) {
      return false;
    }
  }
  
  /// Update last auth time
  static Future<void> _updateLastAuthTime() async {
    await _secureStorage.write(
      key: _lastAuthKey, 
      value: DateTime.now().toIso8601String(),
    );
  }
  
  /// Hash password using SHA256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'letchatt_private_salt');
    return sha256.convert(bytes).toString();
  }
  
  /// Add chat to private list
  static Future<bool> addToPrivate({
    required String chatRoomId,
    required String chatName,
    required String chatAvatar,
    required String chatType, // 'p2p' or 'group'
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      // Store in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .doc(chatRoomId)
          .set({
        'chatRoomId': chatRoomId,
        'chatName': chatName,
        'chatAvatar': chatAvatar,
        'chatType': chatType,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ PrivateChatService: Chat added to private: $chatRoomId');
      return true;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error adding to private: $e');
      return false;
    }
  }
  
  /// Remove chat from private list
  static Future<bool> removeFromPrivate(String chatRoomId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .doc(chatRoomId)
          .delete();
      
      debugPrint('✅ PrivateChatService: Chat removed from private: $chatRoomId');
      return true;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error removing from private: $e');
      return false;
    }
  }
  
  /// Check if chat is in private list
  static Future<bool> isPrivate(String chatRoomId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .doc(chatRoomId)
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error checking private status: $e');
      return false;
    }
  }
  
  /// Get all private chat IDs
  static Future<List<String>> getPrivateChatIds() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ PrivateChatService: Error getting private chat IDs: $e');
      return [];
    }
  }
  
  /// Get all private chats
  static Stream<QuerySnapshot> getPrivateChatsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('privateChats')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
  
  /// Get private chats count
  static Future<int> getPrivateChatsCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear session (logout from private)
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _lastAuthKey);
  }
}
