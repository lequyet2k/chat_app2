import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage user online/offline status
class UserPresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Set user status to online
  Future<void> setUserOnline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ [Presence] No authenticated user - cannot set online');
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'status': 'Online',
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('✅ [Presence] User set to ONLINE: ${user.uid}');
    } catch (e) {
      print('❌ [Presence] Error setting user online: $e');
    }
  }

  /// Set user status to offline
  Future<void> setUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ [Presence] No authenticated user - cannot set offline');
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'status': 'Offline',
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('✅ [Presence] User set to OFFLINE: ${user.uid}');
    } catch (e) {
      print('❌ [Presence] Error setting user offline: $e');
    }
  }

  /// Get user status stream (for real-time updates)
  Stream<DocumentSnapshot> getUserStatusStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Get user status (one-time read)
  Future<String> getUserStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final status = doc.data()?['status'] as String?;
        return status ?? 'Offline';
      }
      return 'Offline';
    } catch (e) {
      print('❌ [Presence] Error getting user status: $e');
      return 'Offline';
    }
  }
}
