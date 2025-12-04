/**
 * Firebase Cloud Functions for Push Notifications
 * 
 * Deploy instructions:
 * 1. cd firebase_functions
 * 2. npm install
 * 3. firebase login
 * 4. firebase init functions (select your project)
 * 5. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: Send notification when new document added to 'notifications' collection
 * Triggers on: Firestore document create in 'notifications/{notificationId}'
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId;

    console.log(`📬 Processing notification: ${notificationId}`);

    try {
      const { token, title, body, data, priority } = notificationData;

      if (!token) {
        console.error('❌ No FCM token provided');
        await snapshot.ref.update({ sent: false, error: 'No FCM token' });
        return null;
      }

      // Build the message
      const message = {
        token: token,
        notification: {
          title: title || 'New Notification',
          body: body || '',
        },
        data: data || {},
        android: {
          priority: priority === 'high' ? 'high' : 'normal',
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_launcher',
            color: '#2196F3',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title || 'New Notification',
                body: body || '',
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // Send the notification
      const response = await messaging.send(message);
      console.log(`✅ Notification sent successfully: ${response}`);

      // Update document with success status
      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return response;
    } catch (error) {
      console.error(`❌ Error sending notification: ${error.message}`);

      // Handle invalid token - remove from user document
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('🗑️ Invalid token, removing from user...');
        
        const receiverId = notificationData.receiverId;
        if (receiverId) {
          await db.collection('users').doc(receiverId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        }
      }

      // Update document with error status
      await snapshot.ref.update({
        sent: false,
        error: error.message,
        errorCode: error.code || 'unknown',
      });

      return null;
    }
  });

/**
 * Cloud Function: Send notification for new chat message
 * Triggers on: Firestore document create in 'chatroom/{chatRoomId}/chats/{messageId}'
 */
exports.onNewChatMessage = functions.firestore
  .document('chatroom/{chatRoomId}/chats/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const chatRoomId = context.params.chatRoomId;

    console.log(`💬 New message in chatroom: ${chatRoomId}`);

    try {
      const senderId = messageData.sendby || messageData.senderId;
      const message = messageData.message || messageData.text || '';
      const type = messageData.type || 'text';

      if (!senderId) {
        console.log('⚠️ No sender ID found');
        return null;
      }

      // Get chatroom info to find receiver
      const chatRoomDoc = await db.collection('chatroom').doc(chatRoomId).get();
      if (!chatRoomDoc.exists) {
        console.log('⚠️ Chatroom not found');
        return null;
      }

      const chatRoomData = chatRoomDoc.data();
      const users = chatRoomData.users || [];

      // Find receiver (the other user in the chat)
      const receiverId = users.find(uid => uid !== senderId);
      if (!receiverId) {
        console.log('⚠️ Receiver not found');
        return null;
      }

      // Get sender info
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.exists ? senderDoc.data().name : 'Someone';

      // Get receiver info and FCM token
      const receiverDoc = await db.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        console.log('⚠️ Receiver user not found');
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;
      const notificationsEnabled = receiverData.notificationsEnabled !== false;

      if (!fcmToken || !notificationsEnabled) {
        console.log('⚠️ Receiver has no token or notifications disabled');
        return null;
      }

      // Format message based on type
      let messagePreview = message;
      switch (type) {
        case 'img':
        case 'image':
          messagePreview = '📷 Sent a photo';
          break;
        case 'video':
          messagePreview = '🎥 Sent a video';
          break;
        case 'audio':
        case 'voice':
          messagePreview = '🎵 Sent a voice message';
          break;
        case 'file':
          messagePreview = '📎 Sent a file';
          break;
        case 'location':
          messagePreview = '📍 Shared a location';
          break;
        default:
          if (message.length > 100) {
            messagePreview = message.substring(0, 100) + '...';
          }
      }

      // Create notification document
      await db.collection('notifications').add({
        token: fcmToken,
        title: senderName,
        body: messagePreview,
        data: {
          type: 'chat',
          chatRoomId: chatRoomId,
          senderId: senderId,
          senderName: senderName,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        receiverId: receiverId,
        senderId: senderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });

      console.log(`✅ Chat notification queued for ${receiverId}`);
      return null;
    } catch (error) {
      console.error(`❌ Error processing chat message: ${error.message}`);
      return null;
    }
  });

/**
 * Cloud Function: Send notification for new group message
 * Triggers on: Firestore document create in 'groups/{groupId}/chats/{messageId}'
 */
exports.onNewGroupMessage = functions.firestore
  .document('groups/{groupId}/chats/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const groupId = context.params.groupId;

    console.log(`👥 New message in group: ${groupId}`);

    try {
      const senderId = messageData.sendby || messageData.senderId;
      const message = messageData.message || messageData.text || '';
      const type = messageData.type || 'text';

      if (!senderId) {
        console.log('⚠️ No sender ID found');
        return null;
      }

      // Get group info
      const groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        console.log('⚠️ Group not found');
        return null;
      }

      const groupData = groupDoc.data();
      const groupName = groupData.name || 'Group';
      const members = groupData.members || [];

      // Get sender info
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.exists ? senderDoc.data().name : 'Someone';

      // Format message based on type
      let messagePreview = message;
      switch (type) {
        case 'img':
        case 'image':
          messagePreview = '📷 Sent a photo';
          break;
        case 'video':
          messagePreview = '🎥 Sent a video';
          break;
        case 'audio':
        case 'voice':
          messagePreview = '🎵 Sent a voice message';
          break;
        default:
          if (message.length > 80) {
            messagePreview = message.substring(0, 80) + '...';
          }
      }

      // Send notification to all members except sender
      const batch = db.batch();
      let notificationCount = 0;

      for (const memberId of members) {
        if (memberId === senderId) continue;

        const memberDoc = await db.collection('users').doc(memberId).get();
        if (!memberDoc.exists) continue;

        const memberData = memberDoc.data();
        const fcmToken = memberData.fcmToken;
        const notificationsEnabled = memberData.notificationsEnabled !== false;

        if (!fcmToken || !notificationsEnabled) continue;

        const notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          token: fcmToken,
          title: groupName,
          body: `${senderName}: ${messagePreview}`,
          data: {
            type: 'group_chat',
            groupId: groupId,
            groupName: groupName,
            senderId: senderId,
            senderName: senderName,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          receiverId: memberId,
          senderId: senderId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          sent: false,
        });
        notificationCount++;
      }

      if (notificationCount > 0) {
        await batch.commit();
        console.log(`✅ Group notifications queued for ${notificationCount} members`);
      }

      return null;
    } catch (error) {
      console.error(`❌ Error processing group message: ${error.message}`);
      return null;
    }
  });

/**
 * Cloud Function: Clean up old notifications (scheduled daily)
 * Deletes notifications older than 7 days
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 3 * * *') // Run at 3 AM every day
  .timeZone('Asia/Ho_Chi_Minh')
  .onRun(async (context) => {
    console.log('🧹 Starting notification cleanup...');

    try {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const oldNotifications = await db.collection('notifications')
        .where('createdAt', '<', sevenDaysAgo)
        .limit(500) // Process in batches
        .get();

      if (oldNotifications.empty) {
        console.log('✅ No old notifications to delete');
        return null;
      }

      const batch = db.batch();
      oldNotifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`✅ Deleted ${oldNotifications.size} old notifications`);

      return null;
    } catch (error) {
      console.error(`❌ Error cleaning up notifications: ${error.message}`);
      return null;
    }
  });

/**
 * Cloud Function: Send notification for incoming call
 * Triggers on: Firestore document create in 'calls/{callId}'
 */
exports.onIncomingCall = functions.firestore
  .document('calls/{callId}')
  .onCreate(async (snapshot, context) => {
    const callData = snapshot.data();
    const callId = context.params.callId;

    console.log(`📞 New call: ${callId}`);

    try {
      const callerId = callData.callerId;
      const receiverId = callData.receiverId;
      const callType = callData.type || 'voice'; // 'voice' or 'video'
      const channelId = callData.channelId || callId;

      if (!callerId || !receiverId) {
        console.log('⚠️ Missing caller or receiver ID');
        return null;
      }

      // Get caller info
      const callerDoc = await db.collection('users').doc(callerId).get();
      const callerName = callerDoc.exists ? callerDoc.data().name : 'Someone';

      // Get receiver info and FCM token
      const receiverDoc = await db.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        console.log('⚠️ Receiver not found');
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        console.log('⚠️ Receiver has no FCM token');
        return null;
      }

      const callTypeIcon = callType === 'video' ? '📹' : '📞';
      const callTypeText = callType === 'video' ? 'Video' : 'Voice';

      // Create high-priority notification for call
      await db.collection('notifications').add({
        token: fcmToken,
        title: `${callTypeIcon} Incoming ${callTypeText} Call`,
        body: `${callerName} is calling you`,
        data: {
          type: 'call',
          callType: callType,
          callId: callId,
          channelId: channelId,
          callerId: callerId,
          callerName: callerName,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        receiverId: receiverId,
        senderId: callerId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
        priority: 'high',
      });

      console.log(`✅ Call notification queued for ${receiverId}`);
      return null;
    } catch (error) {
      console.error(`❌ Error processing call: ${error.message}`);
      return null;
    }
  });
