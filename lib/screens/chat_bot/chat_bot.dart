import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../resources/methods.dart';

class ChatBot extends StatefulWidget {
  User user;
  ChatBot({Key? key,required this.user});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  late DialogFlowtter dialogFlowtter;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _message = TextEditingController();
  final itemScrollController = ItemScrollController();

  void initState() {
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToIndex());
    super.initState();
  }

  void scrollToIndex() async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatvsBot').get().then((value) {
      itemScrollController.jumpTo(index: value.docs.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black,),
                ),
                SizedBox(width: 2,),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/chatbot.png'),
                  maxRadius: 20,
                ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'chatBot',
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6,),
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
                stream: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatvsBot').orderBy('timeStamp',descending: false).snapshots(),
                builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
                  if(snapshot.data!= null){
                    return ScrollablePositionedList.builder(
                      itemCount: snapshot.data?.docs.length as int,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data?.docs[index].data() as Map<String, dynamic>;
                        return messages(size, map,context);
                      },
                      itemScrollController: itemScrollController,
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
              // padding: EdgeInsets.only(bottom: 10,top: 10),
              height: size.height / 16,
              width: double.infinity,
              color: Colors.white70,
              child: Row(
                children: <Widget>[
                  SizedBox(width: 10,),
                  // SizedBox(width: 15,),
                  Expanded(
                    child: Container(
                      height: size.height / 20.8,
                      // decoration: BoxDecoration(
                      //     color: Colors.grey.shade300,
                      //     borderRadius: BorderRadius.circular(25),
                      // ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          // hintText: "Aa",
                          // hintStyle: TextStyle(color: Colors.white38),
                          // contentPadding: EdgeInsets.all(8.0),
                          prefixIcon: Icon(Icons.abc),
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
                    icon: Icon(Icons.send, color: Colors.blueAccent,),
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
        SizedBox(width: 2,),
        map['sendBy'] !=  widget.user.displayName?
        Container(
          height: size.width / 13 ,
          width: size.width / 13 ,
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/images/chatbot.png'),
            maxRadius: 30,
          ),
        ): Container(
        ),
        Container(
          width: map['sendBy'] == widget.user.displayName ?  size.width * 0.98 : size.width * 0.7,
          alignment: map['sendBy'] == widget.user.displayName ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints( maxWidth: size.width / 1.5),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.blueAccent,
            ),
            child: Text(
              map['message'],
              style: TextStyle(color: Colors.white,fontSize: 17),
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
        'sendBy' : _auth.currentUser!.displayName,
        'message' : message,
        'type' : "text",
        'time' :  timeForMessage(DateTime.now().toString()),
        'timeStamp' : DateTime.now(),
      };
      await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatvsBot').add(messages);

      // setState(() {
      //   addMessage(Message(text: DialogText(text: [text])), true);
      // });

      DetectIntentResponse response = await dialogFlowtter.detectIntent(
          queryInput: QueryInput(text: TextInput(text: message)));
      if (response.message == null) {
        return;
      }else{
        await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatvsBot').add({
          'sendBy' : 'bot',
          'message' : response.message!.text?.text![0],
          'type' : "text",
          "time" : timeForMessage(DateTime.now().toString()),
          'timeStamp' : DateTime.now(),
        });
      };
    } else {
      print('Enter some text');
    }
    scrollToIndex();
  }
}

