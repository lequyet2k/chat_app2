
import 'package:flutter/material.dart';
import 'package:my_porject/models/call_model.dart';
import 'package:my_porject/screens/callscreen/call_methods.dart';
import 'package:my_porject/screens/callscreen/call_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PickUpScreen extends StatelessWidget {
  final Call call;
  final CallMethods callMethods = CallMethods();
  PickUpScreen({Key? key, required this.call}) : super(key: key);

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
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
              call.callerPic!,
              height: 150,
              width: 150,
            ),
            SizedBox(height: 15,),
            Text(
              call.callerName!,
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
                      await callMethods.endCall(call : call);
                    },
                    color: Colors.redAccent,
                    icon: Icon(Icons.call_end),
                ),
                SizedBox(width: 25,),
                IconButton(
                    onPressed: () async {
                      await _handleCameraAndMic(Permission.camera);
                      await _handleCameraAndMic(Permission.microphone);
                      await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CallScreen(call: call)),
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
