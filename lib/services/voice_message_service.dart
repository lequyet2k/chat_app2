import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for recording and uploading voice messages
class VoiceMessageService {
  static final AudioRecorder _audioRecorder = AudioRecorder();
  static String? _currentRecordingPath;
  static bool _isRecording = false;

  /// Check if microphone permission is granted
  static Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    print('🎤 [VoiceMessage] Microphone permission status: $status');
    
    if (status.isDenied) {
      print('🎤 [VoiceMessage] Requesting microphone permission...');
      final result = await Permission.microphone.request();
      print('🎤 [VoiceMessage] Permission request result: $result');
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  /// Start recording voice message
  static Future<bool> startRecording() async {
    try {
      print('🎤 [VoiceMessage] Starting recording...');
      
      // Check permission first
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        print('❌ [VoiceMessage] Microphone permission denied');
        return false;
      }

      // Check if already recording
      if (_isRecording) {
        print('⚠️ [VoiceMessage] Already recording');
        return false;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      print('🎤 [VoiceMessage] Recording to: $_currentRecordingPath');

      // Start recording
      final config = const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;

      print('✅ [VoiceMessage] Recording started successfully');
      return true;
    } catch (e) {
      print('❌ [VoiceMessage] Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  static Future<String?> stopRecording() async {
    try {
      print('🎤 [VoiceMessage] Stopping recording...');

      if (!_isRecording) {
        print('⚠️ [VoiceMessage] Not currently recording');
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      print('✅ [VoiceMessage] Recording stopped: $path');
      return path ?? _currentRecordingPath;
    } catch (e) {
      print('❌ [VoiceMessage] Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording
  static Future<void> cancelRecording() async {
    try {
      print('🎤 [VoiceMessage] Cancelling recording...');
      
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }

      // Delete the file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('✅ [VoiceMessage] Recording file deleted');
        }
      }

      _currentRecordingPath = null;
    } catch (e) {
      print('❌ [VoiceMessage] Error cancelling recording: $e');
    }
  }

  /// Upload voice message to Firebase Storage
  static Future<Map<String, dynamic>?> uploadVoiceMessage(String filePath) async {
    try {
      print('☁️ [VoiceMessage] Uploading voice message...');
      print('☁️ [VoiceMessage] File path: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ [VoiceMessage] File does not exist: $filePath');
        return null;
      }

      // Get file size and duration
      final fileSize = await file.length();
      print('☁️ [VoiceMessage] File size: ${fileSize} bytes');

      // Generate unique filename
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance.ref().child('voice_messages/$fileName');

      print('☁️ [VoiceMessage] Uploading to Firebase Storage...');

      // Upload file
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ [VoiceMessage] Upload successful!');
      print('✅ [VoiceMessage] Download URL: $downloadUrl');

      // Delete local file after upload
      await file.delete();
      print('✅ [VoiceMessage] Local file deleted');

      return {
        'url': downloadUrl,
        'size': fileSize,
        'duration': 0, // Duration can be calculated if needed
      };
    } catch (e) {
      print('❌ [VoiceMessage] Error uploading voice message: $e');
      return null;
    }
  }

  /// Check if currently recording
  static bool get isRecording => _isRecording;

  /// Dispose resources
  static Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    await _audioRecorder.dispose();
  }
}
