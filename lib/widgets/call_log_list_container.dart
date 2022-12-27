import 'package:flutter/material.dart';
import 'package:my_porject/db/log_repository.dart';

import '../models/log_model.dart';

class CallLogListContainer extends StatelessWidget {
  const CallLogListContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: LogRepository.getLogs(),
      builder: (context, AsyncSnapshot snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if(snapshot.hasData) {
          List<dynamic> logList = snapshot.data;

          if(logList.isNotEmpty) {
            return ListView.builder(
              itemCount: logList.length,
                itemBuilder: (context, index) {
                  Log _log = logList[index];
                  bool hasDialled = _log.callStatus == "dialled";
                  return Container();
                },
            );
          }

          return Text('Call some one pls');
        }
        return Text("No Call Logs");
      },
    );
  }
}
