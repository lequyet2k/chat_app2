import 'dart:core';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:my_porject/screens/chat_screen.dart';
import 'package:my_porject/resources/methods.dart';
import 'package:my_porject/screens/group/group_chat_room.dart';
import 'package:my_porject/services/private_chat_service.dart';

// ignore: must_be_immutable
class ConversationList extends StatefulWidget {
  User user;
  Map<String, dynamic> chatHistory ;
  bool isDeviceConnected;
  ConversationList({key, required this.chatHistory,required this.user, required this.isDeviceConnected});

  @override
  _ConversationListState createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {

  late Map<String, dynamic> userMap;

  final DateFormat formatter = DateFormat('Hm');

  bool? isDeviceConnected;

  void conversation() async {
    FirebaseFirestore _firestore =  FirebaseFirestore.instance;

    await _firestore.collection('users').where("uid", isEqualTo: widget.chatHistory['uid']).get().then((value) {
      setState(() {
        userMap = value.docs[0].data() ;
      });
    });
    widget.isDeviceConnected = await InternetConnection().hasInternetAccess;

    String roomId = ChatRoomId().chatRoomId(widget.user.displayName,widget.chatHistory['name']);

    if(mounted) {
      setState(() {
        isDeviceConnected = widget.isDeviceConnected;
      });
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return ChatScreen(chatRoomId: roomId, userMap: userMap, user: widget.user,isDeviceConnected : isDeviceConnected!);
          })
      );
    }

  }
  void groupConversation() async {
    widget.isDeviceConnected = await InternetConnection().hasInternetAccess;
    if(mounted) {
      setState(() {
        isDeviceConnected = widget.isDeviceConnected;
      });
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context){
            return GroupChatRoom(groupChatId: widget.chatHistory['uid'], groupName: widget.chatHistory['name'], user: widget.user, isDeviceConnected: isDeviceConnected!,);
          })
      );
    }
  }

  void _showOptionsMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Chat info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        widget.chatHistory['avatar'] ?? '',
                      ),
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatHistory['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            widget.chatHistory['datatype'] == 'group' ? 'Group' : 'Private Chat',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              // Move to Private option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
                ),
                title: const Text('Move to Private'),
                subtitle: Text(
                  'Protect this chat with password',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _moveToPrivate();
                },
              ),
              // Delete chat option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red[400]),
                ),
                title: Text('Delete Chat', style: TextStyle(color: Colors.red[400])),
                subtitle: Text(
                  'Remove from your chat list',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveToPrivate() async {
    final chatRoomId = widget.chatHistory['datatype'] == 'group'
        ? widget.chatHistory['uid']
        : ChatRoomId().chatRoomId(widget.user.displayName, widget.chatHistory['name']);
    
    final success = await PrivateChatService.addToPrivate(
      chatRoomId: chatRoomId,
      chatName: widget.chatHistory['name'] ?? 'Unknown',
      chatAvatar: widget.chatHistory['avatar'] ?? '',
      chatType: widget.chatHistory['datatype'] ?? 'p2p',
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.lock, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Chat moved to Private'),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[400]),
            const SizedBox(width: 12),
            const Text('Delete Chat'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this chat with ${widget.chatHistory['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chatHistory')
          .doc(widget.chatHistory['uid'])
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(widget.chatHistory['datatype'] == 'group') {
          groupConversation();
        }else {
          conversation();
        }
      },
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.chatHistory['isRead'] == false 
                        ? Colors.blue 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: widget.chatHistory['avatar'] != null && 
                                   widget.chatHistory['avatar'].toString().isNotEmpty
                      ? CachedNetworkImageProvider(widget.chatHistory['avatar'])
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  radius: 28,
                  child: widget.chatHistory['avatar'] == null || 
                         widget.chatHistory['avatar'].toString().isEmpty
                      ? Icon(Icons.person, color: Colors.grey.shade600, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.chatHistory['name'].toString().length >= 25
                                ? '${widget.chatHistory['name'].toString().substring(0, 25)}...'
                                : widget.chatHistory['name'],
                            style: TextStyle(
                              fontWeight: widget.chatHistory['isRead'] == false 
                                  ? FontWeight.w700 
                                  : FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.chatHistory['isRead'] == false) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.chatHistory['lastMessage'].toString().length >= 30
                                ? '${widget.chatHistory['lastMessage'].toString().substring(0, 30)}...'
                                : widget.chatHistory['lastMessage'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: widget.chatHistory['isRead'] == false 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                              color: widget.chatHistory['isRead'] == false 
                                  ? Colors.grey[700]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          extractTimeSafe(widget.chatHistory['time']?.toString()),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: widget.chatHistory['isRead'] == false 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
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
