import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';

import '../../resources/methods.dart';

// ignore: must_be_immutable
class ChatBot extends StatefulWidget {
  User user;
  ChatBot({Key? key, required this.user});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  late DialogFlowtter dialogFlowtter;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _message = TextEditingController();
  late ScrollController controller = ScrollController();

  @override
  void initState() {
    // DialogFlowtter temporarily disabled - API needs update
    // DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[100]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/chatbot.png'),
                radius: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AI Chat Bot',
                    style: TextStyle(
                      color: Colors.grey[100],
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Always online',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[100]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('chatvsBot')
                    .orderBy('timeStamp', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (controller.hasClients) {
                      controller.jumpTo(controller.position.maxScrollExtent);
                    }
                  });
                  if (snapshot.data != null) {
                    return GroupedListView<QueryDocumentSnapshot<Object?>,
                        String>(
                      shrinkWrap: true,
                      groupBy: (element) => element['time'],
                      elements: snapshot.data?.docs
                          as List<QueryDocumentSnapshot<Object?>>,
                      groupSeparatorBuilder: (String groupByValue) => Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${groupByValue.substring(11, 16)}, ${groupByValue.substring(0, 10)}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      indexedItemBuilder: (context, element, index) {
                        Map<String, dynamic> map = snapshot.data?.docs[index]
                            .data() as Map<String, dynamic>;
                        return messages(size, map, context);
                      },
                      controller: controller,
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: 44, maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _message,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Ask me anything...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      if (_message.text.trim().isNotEmpty) {
                        sendMessage();
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    bool isUser = map['sendBy'] == widget.user.displayName;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/chatbot.png'),
                radius: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 4),
                  topRight: Radius.circular(isUser ? 4 : 18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                color: isUser ? Colors.blue : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                map['message'],
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey[800],
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  sendMessage() async {
    String message;
    message = _message.text;
    setState(() {
      _message.clear();
    });
    if (message.isNotEmpty) {
      Map<String, dynamic> messages = {
        'sendBy': _auth.currentUser!.displayName,
        'message': message,
        'type': "text",
        'time': timeForMessage(DateTime.now().toString()),
        'timeStamp': DateTime.now(),
      };
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('chatvsBot')
          .add(messages);

      // setState(() {
      //   addMessage(Message(text: DialogText(text: [text])), true);
      // });

      DetectIntentResponse response = await dialogFlowtter.detectIntent(
          queryInput: QueryInput(text: TextInput(text: message)));
      if (response.message == null) {
        return;
      } else {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('chatvsBot')
            .add({
          'sendBy': 'bot',
          'message': response.message!.text?.text![0],
          'type': "text",
          "time": timeForMessage(DateTime.now().toString()),
          'timeStamp': DateTime.now(),
        });
      }
      ;
    } else {
      print('Enter some text');
    }
  }
}
