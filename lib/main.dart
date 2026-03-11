import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAMO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _fcmToken = '';
  String _lastMessage = '';

  static const String _apiBaseUrl = 'http://54.180.179.231:8080';

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      if (token != null) {
        setState(() => _fcmToken = token);
        await _registerToken(token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        setState(() => _fcmToken = newToken);
        _registerToken(newToken);
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _lastMessage =
            '${message.notification?.title}: ${message.notification?.body}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lastMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _lastMessage =
            '${message.notification?.title}: ${message.notification?.body}';
      });
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await http.post(
        Uri.parse('$_apiBaseUrl/api/fcm/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'platform': Theme.of(context).platform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        }),
      );
    } catch (e) {
      debugPrint('Token registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('DAMO'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _fcmToken.isEmpty
                  ? 'FCM 토큰 대기중...'
                  : 'FCM 토큰: ${_fcmToken.substring(0, 20)}...',
            ),
            const SizedBox(height: 16),
            if (_lastMessage.isNotEmpty) ...[
              const Text(
                '마지막 알림',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_lastMessage),
            ],
          ],
        ),
      ),
    );
  }
}
