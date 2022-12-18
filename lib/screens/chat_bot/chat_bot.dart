import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
                Icon(Icons.settings, color: Colors.black54,)
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.grey.shade500,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('chatvsBot').orderBy('time',descending: false).snapshots(),
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
              padding: EdgeInsets.only(bottom: 13,top: 10),
              height: size.height / 16,
              width: double.infinity,
              color: Colors.black,
              child: Row(
                children: <Widget>[
                  SizedBox(width: 15,),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade700,
                        hintText: "Aa",
                        hintStyle: TextStyle(color: Colors.white30),
                        contentPadding: EdgeInsets.all(8.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      controller: _message,
                    ),
                  ),
                  Container(
                    child: IconButton(
                      onPressed: () {
                        sendMessage(_message.text);
                       _message.clear();
                      },
                      icon: Icon(Icons.send, color: Colors.blueAccent,),
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
              color: Colors.black,
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

  sendMessage(String text) async {
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
        'time' :  DateTime.now(),
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
          "time" : DateTime.now(),
        });
      };
    } else {
      print('Enter some text');
    }
    scrollToIndex();
  }
}

