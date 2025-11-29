import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic> userMap;

  const ChatSettingsScreen({
    super.key,
    required this.chatRoomId,
    required this.userMap,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _autoDeleteEnabled = false;
  int _selectedDuration = 0; // 0 = off, 1 = 1min, 5 = 5min, 60 = 1hour, 1440 = 24hours
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _autoDeleteEnabled = data['autoDeleteEnabled'] ?? false;
          _selectedDuration = data['autoDeleteDuration'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _firestore.collection('chatroom').doc(widget.chatRoomId).set({
        'autoDeleteEnabled': _autoDeleteEnabled,
        'autoDeleteDuration': _selectedDuration,
        'autoDeleteUpdatedBy': _auth.currentUser!.uid,
        'autoDeleteUpdatedAt': DateTime.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  Widget _buildDurationOption(int minutes, String label, IconData icon) {
    final isSelected = _selectedDuration == minutes;
    
    return GestureDetector(
      onTap: _autoDeleteEnabled
          ? () {
              setState(() {
                _selectedDuration = minutes;
              });
              _saveSettings();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey[800]
              : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.grey[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : _autoDeleteEnabled
                      ? Colors.grey[800]
                      : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : (_autoDeleteEnabled ? Colors.grey[900] : Colors.grey),
                    ),
                  ),
                  if (minutes > 0)
                    Text(
                      'Messages will be deleted after $label',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.grey[300] : (_autoDeleteEnabled
                            ? Colors.grey[600]
                            : Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chat Settings'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(
                            Icons.auto_delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-Delete Messages',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Chat with ${widget.userMap['name']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Enable/Disable Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _autoDeleteEnabled
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            size: 48,
                            color: _autoDeleteEnabled
                                ? Colors.grey[800]
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Auto-Delete',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _autoDeleteEnabled
                                      ? 'Messages will be deleted automatically'
                                      : 'Messages will not be deleted',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoDeleteEnabled,
                            onChanged: (value) {
                              setState(() {
                                _autoDeleteEnabled = value;
                                if (!value) {
                                  _selectedDuration = 0;
                                }
                              });
                              _saveSettings();
                            },
                            activeTrackColor: Colors.grey[700],
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Duration Options
                    if (_autoDeleteEnabled) ...[
                      const Text(
                        'Select Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how long messages should be kept',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDurationOption(1, '1 Minute', Icons.timer),
                      _buildDurationOption(5, '5 Minutes', Icons.timer_3),
                      _buildDurationOption(60, '1 Hour', Icons.hourglass_bottom),
                      _buildDurationOption(1440, '24 Hours', Icons.today),
                    ],

                    const SizedBox(height: 24),

                    // Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How it works',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Messages older than the selected duration will be automatically deleted from this chat. This setting applies to both users in this conversation.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber[900],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Security Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All messages remain end-to-end encrypted. Auto-delete only removes messages from the database after the specified time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
