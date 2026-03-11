import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'data/datasource/fcm_remote_datasource.dart';
import 'data/repository/fcm_repository_impl.dart';
import 'domain/usecase/register_fcm_token_usecase.dart';
import 'firebase_options.dart';
import 'presentation/bloc/fcm_bloc.dart';
import 'presentation/bloc/fcm_event.dart';
import 'presentation/page/home_page.dart';

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

  // DI
  final apiClient = ApiClient();
  final fcmDataSource = FcmRemoteDataSource(apiClient: apiClient);
  final fcmRepository = FcmRepositoryImpl(fcmDataSource);
  final registerFcmTokenUseCase = RegisterFcmTokenUseCase(fcmRepository);

  final analyticsInstance = FirebaseAnalytics.instance;

  runApp(MyApp(
    registerFcmTokenUseCase: registerFcmTokenUseCase,
    analytics: analyticsInstance,
  ));
}

class MyApp extends StatelessWidget {
  final RegisterFcmTokenUseCase registerFcmTokenUseCase;
  final FirebaseAnalytics analytics;

  const MyApp({
    super.key,
    required this.registerFcmTokenUseCase,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FcmBloc(
        registerFcmTokenUseCase: registerFcmTokenUseCase,
      )..add(FcmInitRequested()),
      child: MaterialApp(
        title: 'DAMO',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        home: const HomePage(),
      ),
    );
  }
}
