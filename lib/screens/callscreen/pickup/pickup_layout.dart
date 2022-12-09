import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/callscreen/call_methods.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/callscreen/pickup/pickup_screen.dart';
import 'package:provider/provider.dart';

import '../../../models/call_model.dart';


class PickUpLayout extends StatelessWidget {

  final Widget scaffold;
  final CallMethods callMethods = CallMethods();

  PickUpLayout({Key? key, required this.scaffold}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return (userProvider.getUser != null) ?
    StreamBuilder<DocumentSnapshot>(
      stream: callMethods.callStream(uid: userProvider.getUser!.uid),
      builder: (context, snapshot) {
        print(snapshot.data?.data());
        if(snapshot.hasData && snapshot.data?.data() != null) {
          Call call = Call.fromMap(snapshot.data?.data() as Map<String, dynamic>);
          if (!call.hasDialled!) {
            return PickUpScreen(call: call);
          }
          return scaffold;
        }
        return scaffold;
      },
    )
        : Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
