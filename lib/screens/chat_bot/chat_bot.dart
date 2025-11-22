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
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 2,
                ),
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/chatbot.png'),
                  maxRadius: 20,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Text(
                        'chatBot',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white,
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
                        height: 30,
                        child: Text(
                          "${groupByValue.substring(11, 16)}, ${groupByValue.substring(0, 10)}",
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
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
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              height: size.height / 15,
              width: double.infinity,
              color: Colors.white70,
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 10,
                  ),
                  // SizedBox(width: 15,),
                  Expanded(
                    child: SizedBox(
                      height: size.height / 20.8,
                      // decoration: BoxDecoration(
                      //     color: Colors.grey.shade300,
                      //     borderRadius: BorderRadius.circular(25),
                      // ),
                      child: TextFormField(
                        autofocus: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          // hintText: "Aa",
                          // hintStyle: TextStyle(color: Colors.white38),
                          // contentPadding: EdgeInsets.all(8.0),
                          prefixIcon: const Icon(
                            Icons.abc,
                            size: 30,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        controller: _message,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: const Icon(
                      Icons.send,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 2,
        ),
        map['sendBy'] != widget.user.displayName
            ? SizedBox(
                height: size.width / 13,
                width: size.width / 13,
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/chatbot.png'),
                  maxRadius: 30,
                ),
              )
            : Container(),
        Container(
          width: map['sendBy'] == widget.user.displayName
              ? size.width * 0.98
              : size.width * 0.7,
          alignment: map['sendBy'] == widget.user.displayName
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: size.width / 1.5),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.blueAccent,
            ),
            child: Text(
              map['message'],
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
        ),
      ],
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
