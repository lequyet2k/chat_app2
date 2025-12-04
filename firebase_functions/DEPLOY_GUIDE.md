# Firebase Cloud Functions Deployment Guide

## Prerequisites

1. **Node.js 18+** installed on your computer
2. **Firebase CLI** installed globally:
   ```bash
   npm install -g firebase-tools
   ```

## Setup Steps

### 1. Login to Firebase
```bash
firebase login
```

### 2. Navigate to functions directory
```bash
cd firebase_functions
```

### 3. Install dependencies
```bash
npm install
```

### 4. Initialize Firebase (if not already done)
```bash
firebase init functions
```
- Select your project: `chatapptest2-93793`
- Choose JavaScript
- Don't overwrite existing files

### 5. Deploy Functions
```bash
firebase deploy --only functions
```

## Functions Overview

| Function | Trigger | Description |
|----------|---------|-------------|
| `sendPushNotification` | Firestore onCreate: `notifications/{id}` | Sends FCM notification from queue |
| `onNewChatMessage` | Firestore onCreate: `chatroom/{id}/chats/{msgId}` | Auto-notify on new chat message |
| `onNewGroupMessage` | Firestore onCreate: `groups/{id}/chats/{msgId}` | Auto-notify group members |
| `onIncomingCall` | Firestore onCreate: `calls/{id}` | Notify on incoming call |
| `cleanupOldNotifications` | Scheduled: Daily 3AM | Delete notifications older than 7 days |

## Testing

### Test sendPushNotification
Add a document to `notifications` collection in Firestore:
```json
{
  "token": "FCM_TOKEN_HERE",
  "title": "Test Notification",
  "body": "This is a test message",
  "data": {
    "type": "test"
  },
  "sent": false
}
```

### View Logs
```bash
firebase functions:log
```

## Troubleshooting

### Error: "messaging/invalid-registration-token"
- The FCM token is invalid or expired
- The function will automatically remove invalid tokens from user documents

### Error: "messaging/registration-token-not-registered"
- User has uninstalled the app or token was refreshed
- The function will automatically clean up

### Functions not triggering?
1. Check Firestore security rules allow Cloud Functions to read/write
2. Verify the collection paths match your app's structure
3. Check Firebase Console → Functions → Logs for errors

## Billing Note

Firebase Cloud Functions require the **Blaze (pay-as-you-go) plan**.
Free tier includes:
- 2 million invocations/month
- 400,000 GB-seconds/month
- 200,000 CPU-seconds/month

Most chat apps stay well within free tier limits.
