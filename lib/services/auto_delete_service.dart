import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service để tự động xóa tin nhắn theo cài đặt của chatroom
class AutoDeleteService {
  static final AutoDeleteService _instance = AutoDeleteService._internal();
  factory AutoDeleteService() => _instance;
  AutoDeleteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map để lưu trữ các timer đang chạy cho mỗi chatroom
  final Map<String, Timer> _activeTimers = {};
  
  // Map để lưu trữ các subscription đang lắng nghe
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  /// Khởi động service cho một chatroom
  /// Gọi khi user mở ChatScreen
  Future<void> startMonitoring(String chatRoomId) async {
    if (kDebugMode) {
      print('🗑️ [AutoDelete] Starting monitoring for chatroom: $chatRoomId');
    }

    // Hủy subscription cũ nếu có
    await _activeSubscriptions[chatRoomId]?.cancel();

    // Lắng nghe thay đổi cài đặt auto-delete của chatroom
    _activeSubscriptions[chatRoomId] = _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final autoDeleteEnabled = data['autoDeleteEnabled'] ?? false;
        final autoDeleteDuration = data['autoDeleteDuration'] ?? 0;

        if (autoDeleteEnabled && autoDeleteDuration > 0) {
          _startAutoDeleteTimer(chatRoomId, autoDeleteDuration);
        } else {
          _stopAutoDeleteTimer(chatRoomId);
        }
      }
    });
  }

  /// Dừng monitoring cho một chatroom
  /// Gọi khi user rời ChatScreen
  Future<void> stopMonitoring(String chatRoomId) async {
    if (kDebugMode) {
      print('🗑️ [AutoDelete] Stopping monitoring for chatroom: $chatRoomId');
    }
    
    await _activeSubscriptions[chatRoomId]?.cancel();
    _activeSubscriptions.remove(chatRoomId);
    _stopAutoDeleteTimer(chatRoomId);
  }

  /// Bắt đầu timer để xóa tin nhắn định kỳ
  void _startAutoDeleteTimer(String chatRoomId, int durationMinutes) {
    // Hủy timer cũ nếu có
    _activeTimers[chatRoomId]?.cancel();

    if (kDebugMode) {
      print('🗑️ [AutoDelete] Starting timer for $chatRoomId - Duration: $durationMinutes minutes');
    }

    // Chạy ngay lập tức lần đầu
    _deleteOldMessages(chatRoomId, durationMinutes);

    // Thiết lập timer chạy định kỳ mỗi 30 giây để kiểm tra và xóa
    _activeTimers[chatRoomId] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _deleteOldMessages(chatRoomId, durationMinutes),
    );
  }

  /// Dừng timer
  void _stopAutoDeleteTimer(String chatRoomId) {
    _activeTimers[chatRoomId]?.cancel();
    _activeTimers.remove(chatRoomId);
    
    if (kDebugMode) {
      print('🗑️ [AutoDelete] Timer stopped for $chatRoomId');
    }
  }

  /// Xóa các tin nhắn cũ hơn thời gian quy định
  Future<void> _deleteOldMessages(String chatRoomId, int durationMinutes) async {
    try {
      // Tính thời điểm cutoff
      final cutoffTime = DateTime.now().subtract(Duration(minutes: durationMinutes));
      
      if (kDebugMode) {
        print('🗑️ [AutoDelete] Checking messages older than: $cutoffTime');
      }

      // Query các tin nhắn cũ hơn cutoff time
      final oldMessages = await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .where('timeStamp', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      if (oldMessages.docs.isEmpty) {
        if (kDebugMode) {
          print('🗑️ [AutoDelete] No old messages to delete');
        }
        return;
      }

      if (kDebugMode) {
        print('🗑️ [AutoDelete] Found ${oldMessages.docs.length} messages to delete');
      }

      // Batch delete để tối ưu performance
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in oldMessages.docs) {
        batch.delete(doc.reference);
        deleteCount++;
        
        // Firestore batch limit là 500, nên commit mỗi 450 documents
        if (deleteCount >= 450) {
          await batch.commit();
          if (kDebugMode) {
            print('🗑️ [AutoDelete] Deleted batch of $deleteCount messages');
          }
          deleteCount = 0;
        }
      }

      // Commit remaining
      if (deleteCount > 0) {
        await batch.commit();
        if (kDebugMode) {
          print('🗑️ [AutoDelete] Deleted final batch of $deleteCount messages');
        }
      }

      if (kDebugMode) {
        print('✅ [AutoDelete] Successfully deleted ${oldMessages.docs.length} old messages');
      }

      // Cập nhật last message trong chatroom nếu cần
      await _updateLastMessage(chatRoomId);

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AutoDelete] Error deleting messages: $e');
      }
    }
  }

  /// Cập nhật last message trong chatroom sau khi xóa
  Future<void> _updateLastMessage(String chatRoomId) async {
    try {
      // Lấy tin nhắn mới nhất còn lại
      final latestMessages = await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .orderBy('timeStamp', descending: true)
          .limit(1)
          .get();

      if (latestMessages.docs.isNotEmpty) {
        final latestMessage = latestMessages.docs.first.data();
        await _firestore.collection('chatroom').doc(chatRoomId).update({
          'lastMessage': latestMessage['message'] ?? '',
          'type': latestMessage['type'] ?? 'text',
        });
      } else {
        // Không còn tin nhắn nào
        await _firestore.collection('chatroom').doc(chatRoomId).update({
          'lastMessage': '',
          'type': 'text',
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AutoDelete] Error updating last message: $e');
      }
    }
  }

  /// Xóa tất cả tin nhắn trong chatroom (manual delete all)
  Future<bool> deleteAllMessages(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('🗑️ [AutoDelete] Deleting ALL messages in chatroom: $chatRoomId');
      }

      final allMessages = await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .get();

      if (allMessages.docs.isEmpty) {
        return true;
      }

      // Batch delete
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in allMessages.docs) {
        batch.delete(doc.reference);
        deleteCount++;

        if (deleteCount >= 450) {
          await batch.commit();
          deleteCount = 0;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
      }

      // Reset last message
      await _firestore.collection('chatroom').doc(chatRoomId).update({
        'lastMessage': '',
        'type': 'text',
      });

      if (kDebugMode) {
        print('✅ [AutoDelete] Successfully deleted all ${allMessages.docs.length} messages');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AutoDelete] Error deleting all messages: $e');
      }
      return false;
    }
  }

  /// Lấy thông tin cài đặt auto-delete của chatroom
  Future<Map<String, dynamic>?> getAutoDeleteSettings(String chatRoomId) async {
    try {
      final doc = await _firestore.collection('chatroom').doc(chatRoomId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'enabled': data['autoDeleteEnabled'] ?? false,
          'duration': data['autoDeleteDuration'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AutoDelete] Error getting settings: $e');
      }
      return null;
    }
  }

  /// Format duration để hiển thị cho user
  static String formatDuration(int minutes) {
    if (minutes == 0) return 'Off';
    if (minutes == 1) return '1 minute';
    if (minutes < 60) return '$minutes minutes';
    if (minutes == 60) return '1 hour';
    if (minutes < 1440) return '${minutes ~/ 60} hours';
    if (minutes == 1440) return '24 hours';
    return '${minutes ~/ 1440} days';
  }

  /// Dọn dẹp tất cả resources
  void dispose() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    if (kDebugMode) {
      print('🗑️ [AutoDelete] Service disposed');
    }
  }
}
