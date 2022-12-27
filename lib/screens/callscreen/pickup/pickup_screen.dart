
import 'package:flutter/material.dart';
import 'package:my_porject/db/log_repository.dart';
import 'package:my_porject/models/call_model.dart';
import 'package:my_porject/screens/callscreen/call_methods.dart';
import 'package:my_porject/screens/callscreen/call_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../models/log_model.dart';

class PickUpScreen extends StatefulWidget {
  final Call call;

  PickUpScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<PickUpScreen> createState() => _PickUpScreenState();
}

class _PickUpScreenState extends State<PickUpScreen> {
  final CallMethods callMethods = CallMethods();

  bool isCallMissed = true;

  addToLocalStorage({required String callStatus}) {
    Log log = Log(
      callerName: widget.call.callerName,
      callerPic: widget.call.callerPic,
      receiverName: widget.call.receiverName,
      receiverPic: widget.call.receiverPic,
      timeStamp: DateTime.now().toString(),
      callStatus: callStatus,
    );

    LogRepository.addLogs(log);
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }
  
  @override
  void dispose() {
    if(isCallMissed) {
      addToLocalStorage(callStatus: 'missed');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Incoming...",
              style: TextStyle(
                fontSize: 30,
              ),
            ),
            SizedBox(height: 50,),
            Image.network(
              widget.call.callerPic!,
              height: 150,
              width: 150,
            ),
            SizedBox(height: 15,),
            Text(
              widget.call.callerName!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 75,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    onPressed: () async {
                      isCallMissed = false;
                      addToLocalStorage(callStatus: 'received');
                      await callMethods.endCall(call : widget.call);
                    },
                    color: Colors.redAccent,
                    icon: Icon(Icons.call_end),
                ),
                SizedBox(width: 25,),
                IconButton(
                    onPressed: () async {
                      isCallMissed = false;
                      addToLocalStorage(callStatus: 'received');
                      await _handleCameraAndMic(Permission.camera);
                      await _handleCameraAndMic(Permission.microphone);
                      await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CallScreen(call: widget.call)),
                      );
                    },
                    color: Colors.green,
                    icon: Icon(Icons.call_made)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
