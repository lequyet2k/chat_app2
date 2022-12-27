import 'package:my_porject/db/log_repository.dart';
import 'package:my_porject/screens/callscreen/call_methods.dart';
import 'package:my_porject/models/call_model.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/callscreen/call_screen.dart';
import 'package:my_porject/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../models/log_model.dart';


class CallUtils {
  static final CallMethods callMethods = CallMethods();

  static dial({required Userr? from, required Userr to , context}) async {
    Call call = Call(
        callerId: from?.uid,
        callerName: from?.name,
        callerPic: from?.avatar,
        receiverId: to.uid,
        receiverName: to.name ,
        receiverPic: to.avatar,
        channelId: Uuid().v1(),
        hasDialled: null,
    );

    Log log = Log(
      callerName: from?.name,
      callerPic: from?.avatar,
      callStatus: "dialled",
      receiverName: to.name,
      receiverPic: to.avatar,
      timeStamp: DateTime.now().toString(),
    );

    bool callMade = await callMethods.makeCall(call: call);

    call.hasDialled = true;
    Future<void> _handleCameraAndMic(Permission permission) async {
      final status = await permission.request();
      print(status);
    }

    if(callMade) {
      LogRepository.addLogs(log);

      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallScreen(call: call)),
      );
    }
  }
}