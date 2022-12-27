
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChatRoomId {
  String chatRoomId(String? user1, String user2){
    if(user1![0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]){
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }
}

Future<Position> getLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if(!serviceEnabled){
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if(permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if(permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if(permission == LocationPermission.deniedForever) {
    return Future.error('Gg, we done');
  }

  return await Geolocator.getCurrentPosition();
}

Future<void> openMap(String lat, String long) async {
  String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$long';

  await canLaunchUrlString(googleUrl)
      ? await launchUrlString(googleUrl)
      : throw 'Could not launch $googleUrl';
}


