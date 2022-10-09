// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Animation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PushNotificationApp(),
    );
  }
}

/// Entry point for the example application.
class PushNotificationApp extends StatefulWidget {
  static const routeName = "/firebase-push";

  const PushNotificationApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PushNotificationAppState createState() => _PushNotificationAppState();
}

class _PushNotificationAppState extends State<PushNotificationApp> {
  @override
  void initState() {
    // getPermission();
    messageListener(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseOptions firebaseConfig = const FirebaseOptions(
        apiKey: "AIzaSyAO_QhzRQl2T6paIF6zreQjVSH_01JQs_g",
        authDomain: "whatsapp-demo-eb9f2.firebaseapp.com",
        projectId: "whatsapp-demo-eb9f2",
        storageBucket: "whatsapp-demo-eb9f2.appspot.com",
        messagingSenderId: "229949023857",
        appId: "1:229949023857:web:06be2743450ff242a19dd0",
        measurementId: "G-CVNJV670ED");

    return FutureBuilder(
      // Initialize FlutterFire
      future: Firebase.initializeApp(options: firebaseConfig),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print('snapshot.error : ${snapshot.error}');
          return const Center(
            child: Text('snapshot.error'),
          );
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          print('android firebase initiated');
          return const NotificationPage();
        }
        // Otherwise, show something whilst waiting for initialization to complete
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> getPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  void messageListener(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      print(
          'Message also contained a notification: ${message.notification!.body}');

      if (message.notification != null) {
        print(
            'Message also contained a notification: ${message.notification!.body}');
        showDialog(
            context: context,
            builder: ((BuildContext context) {
              return DynamicDialog(
                  title: message.notification!.title,
                  body: message.notification!.body);
            }));
      }
    });
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<NotificationPage> {
  String? _token;
  Stream<String>? _tokenStream;
  int notificationCount = 0;

  void setToken(String token) {
    print('FCM TokenToken: $token');
    setState(() {
      _token = token;
    });
  }

  @override
  void initState() {
    super.initState();
    //get token?
    FirebaseMessaging.instance
        .getToken(
            vapidKey:
                'BJxjxFBdiPJOby04MwOJtLAGLM9UxyDebYyFc57SLge5SxdArDLF1uGOOWDVSc_ezYFQEftGJ0IZOJZni_MKrko')
        .then((token) => {setToken(token!)});
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream?.listen(setToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Firebase push notification'),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(10),
            elevation: 10,
            child: ListTile(
              title: Center(
                child: OutlinedButton.icon(
                  label: const Text('Push Notification',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  onPressed: () {
                    sendPushMessageToWeb();
                  },
                  icon: const Icon(Icons.notifications),
                ),
              ),
            ),
          ),
        ));
  }

  //send notification
  sendPushMessageToWeb() async {
    if (_token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }
    try {
      await http
          .post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization':
                  'key=AAAANYoHpnE:APA91bGt9A534YZuJRzqs0v_baoY090jGcIYbvJ5aQ9-e7fjIPsw0qVYssCVToDnnWEV9UheMxZ_EI7rl2INeVdV4G8Q8kR_qpdfqUFZpqF4bPwUFxFef4D_hELYPe1MQ4C-3m7H3OGQ'
            },
            body: json.encode({
              'to': _token,
              'message': {
                'token': _token,
              },
              "notification": {
                "title": "Push Notification",
                "body": "Firebase  push notification"
              }
            }),
          )
          .then((value) => print(value.body));
      print('FCM request for web sent!');
    } catch (e) {
      print(e);
    }
  }
}

//push notification dialog for foreground
class DynamicDialog extends StatefulWidget {
  final title;
  final body;
  // ignore: use_key_in_widget_constructors
  const DynamicDialog({this.title, this.body});
  @override
  // ignore: library_private_types_in_public_api
  _DynamicDialogState createState() => _DynamicDialogState();
}

class _DynamicDialogState extends State<DynamicDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      actions: <Widget>[
        OutlinedButton.icon(
            label: const Text('Close'),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close))
      ],
      content: Text(widget.body),
    );
  }
}
