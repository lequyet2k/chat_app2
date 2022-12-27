class Log {
  int? logId;
  String? callerName;
  String? callerPic;
  String? receiverName;
  String? receiverPic;
  String? callStatus;
  String? timestamp;

  Log({
    required this.logId,
    required this.callerName,
    required this.callerPic,
    required this.receiverName,
    required this.receiverPic,
    required this.callStatus,
    required this.timestamp,
  });

  // to map
  Map<String, dynamic> toMap(Log log) {
    Map<String, dynamic> logMap = Map();
    logMap["log_id"] = log.logId;
    logMap["caller_name"] = log.callerName;
    logMap["caller_pic"] = log.callerPic;
    logMap["receiver_name"] = log.receiverName;
    logMap["receiver_pic"] = log.receiverPic;
    logMap["call_status"] = log.callStatus;
    logMap["timestamp"] = log.timestamp;
    return logMap;
  }

  Log.fromMap(Map logMap) {
    logId = logMap["log_id"];
    callerName = logMap["caller_name"];
    callerPic = logMap["caller_pic"];
    receiverName = logMap["receiver_name"];
    receiverPic = logMap["receiver_pic"];
    callStatus = logMap["call_status"];
    timestamp = logMap["timestamp"];
  }
}