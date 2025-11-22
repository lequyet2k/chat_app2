import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'key_manager.dart';
import 'package:flutter/foundation.dart';

/// Encrypted Chat Service
///
/// Provides high-level methods for sending and receiving encrypted messages
class EncryptedChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send an encrypted text message
  ///
  /// Parameters:
  /// - recipientUid: User ID of the recipient
  /// - message: Plain text message
  /// - chatRoomId: Chat room document ID
  /// - additionalData: Any extra fields to add to the message
  ///
  /// Returns: true if successful, false otherwise
  static Future<bool> sendEncryptedMessage({
    required String recipientUid,
    required String message,
    required String chatRoomId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get recipient's public key
      final recipientPublicKey =
          await KeyManager.getUserPublicKey(recipientUid);

      if (recipientPublicKey == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Recipient does not have encryption enabled');
        }
        // Fallback to unencrypted message
        return false;
      }

      // Encrypt the message
      final encryptedData = EncryptionService.encryptMessage(
        message,
        recipientPublicKey,
      );

      // Prepare message data
      final messageData = {
        'sendBy': _auth.currentUser!.displayName,
        'encrypted': true, // Mark as encrypted
        'encryptedMessage': encryptedData['encryptedMessage'],
        'encryptedAESKey': encryptedData['encryptedAESKey'],
        'iv': encryptedData['iv'],
        'type': 'text',
        'timeStamp': DateTime.now(),
        ...?additionalData,
      };

      // Send to Firestore
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .add(messageData);

      if (kDebugMode) {
        debugPrint('✅ Encrypted message sent successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending encrypted message: $e');
      }
      return false;
    }
  }

  /// Decrypt a received message
  ///
  /// Parameters:
  /// - messageData: Map containing encrypted message data from Firestore
  ///
  /// Returns: Decrypted message string, or error message if decryption fails
  static Future<String> decryptMessage(Map<String, dynamic> messageData) async {
    try {
      // Check if message is encrypted
      if (messageData['encrypted'] != true) {
        // Return original message if not encrypted
        return messageData['message'] ?? '';
      }

      // Get user's private key
      final privateKey = await KeyManager.getPrivateKey();

      if (privateKey == null) {
        return '[Encryption keys not found]';
      }

      // Prepare encrypted data
      final encryptedData = {
        'encryptedMessage': messageData['encryptedMessage'] as String,
        'encryptedAESKey': messageData['encryptedAESKey'] as String,
        'iv': messageData['iv'] as String,
      };

      // Decrypt message
      final decryptedMessage = EncryptionService.decryptMessage(
        encryptedData,
        privateKey,
      );

      return decryptedMessage;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error decrypting message: $e');
      }
      return '[Decryption failed]';
    }
  }

  /// Check if both users have encryption enabled
  static Future<bool> canEncryptChat(String otherUserId) async {
    try {
      // Check if current user has keys
      final hasCurrentUserKeys = await KeyManager.hasKeys();

      if (!hasCurrentUserKeys) {
        return false;
      }

      // Check if other user has encryption enabled
      final otherUserPublicKey = await KeyManager.getUserPublicKey(otherUserId);

      return otherUserPublicKey != null;
    } catch (e) {
      return false;
    }
  }

  /// Send unencrypted message (fallback)
  static Future<bool> sendUnencryptedMessage({
    required String message,
    required String chatRoomId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final messageData = {
        'sendBy': _auth.currentUser!.displayName,
        'message': message,
        'encrypted': false,
        'type': 'text',
        'timeStamp': DateTime.now(),
        ...?additionalData,
      };

      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .add(messageData);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending message: $e');
      }
      return false;
    }
  }
}
