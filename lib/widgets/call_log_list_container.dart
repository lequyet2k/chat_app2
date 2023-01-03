import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/db/log_repository.dart';

import '../models/log_model.dart';
import '../resources/methods.dart';

class CallLogListContainer extends StatelessWidget {
  const CallLogListContainer({Key? key}) : super(key: key);

  getIcon(String? callStatus) {
    Icon _icon;
    double _iconSize = 18;

    switch (callStatus) {
      case 'dialled':
        _icon = Icon(
          Icons.call_made,
          size: _iconSize,
          color: Colors.green,
        );
        break;

      case 'missed':
        _icon = Icon(
          Icons.call_missed,
          color: Colors.red,
          size: _iconSize,
        );
        break;

      default:
        _icon = Icon(
          Icons.call_received,
          size: _iconSize,
          color: Colors.grey,
        );
        break;
    }

    return Container(
      margin: EdgeInsets.only(right: 5),
      child: _icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: FutureBuilder<dynamic>(
          future: LogRepository.getLogs(),
          builder: (context, AsyncSnapshot snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if(snapshot.hasData) {
              List<dynamic> list = snapshot.data;
              List<dynamic> logList = list.reversed.toList();
              if(logList.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(0),
                  shrinkWrap: true,
                  reverse: false,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: logList.length,
                    itemBuilder: (context, index) {
                      Log _log = logList[index];
                      bool hasDialled = _log.callStatus == "dialled";
                      return GestureDetector(
                        onLongPress: () {
                          showDialog(
                              context: context,
                              builder: (context) =>  AlertDialog(
                                title: Text("Delete this log?"),
                                content: Text("Are you sure to delete this log?"),
                                actions: <Widget>[
                                  TextButton(
                                      onPressed: () async {
                                        Navigator.maybePop(context);
                                        await LogRepository.deleteLogs(index);
                                      },
                                      child: Text("Yes"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.maybePop(context);
                                    },
                                    child: Text("No"),
                                  ),
                                ],
                              )
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 16, right: 16, top : 10, bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: hasDialled  ? CachedNetworkImageProvider(_log.receiverPic!) : CachedNetworkImageProvider(_log.callerPic!)  ,
                                maxRadius: 25,
                              ),
                              SizedBox(width: 12,),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasDialled ? _log.receiverName! : _log.callerName!,
                                      style: TextStyle(
                                        fontSize: 16,
                                      )
                                    ),
                                    SizedBox(height: 5,),
                                    Row(
                                      children: [
                                        getIcon(_log.callStatus),
                                        SizedBox(width: 5,),
                                        Text(
                                          _log.timeStamp!.substring(11,16),
                                          style: TextStyle(
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(" - "),
                                        Text(
                                          _log.timeStamp!.substring(0,10),
                                          style: TextStyle(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                );
              }
              return Container();
            }
            return const Text("No Call Logs");
          },
        ),
      ),
    );
  }
}
