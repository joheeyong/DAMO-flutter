import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/notification_message.dart';
import '../../domain/usecase/register_fcm_token_usecase.dart';
import 'fcm_event.dart';
import 'fcm_state.dart';

class FcmBloc extends Bloc<FcmEvent, FcmState> {
  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  FcmBloc({required RegisterFcmTokenUseCase registerFcmTokenUseCase})
      : _registerFcmTokenUseCase = registerFcmTokenUseCase,
        super(const FcmState()) {
    on<FcmInitRequested>(_onInit);
    on<FcmTokenReceived>(_onTokenReceived);
    on<FcmNotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onInit(FcmInitRequested event, Emitter<FcmState> emit) async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      emit(state.copyWith(isInitialized: true));
      return;
    }

    final token = await _registerFcmTokenUseCase.getToken();
    if (token != null) {
      add(FcmTokenReceived(token));
    }

    _tokenRefreshSub = _registerFcmTokenUseCase.onTokenRefresh().listen(
      (newToken) => add(FcmTokenReceived(newToken)),
    );

    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        add(FcmNotificationReceived(NotificationMessage(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        )));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.notification != null) {
        add(FcmNotificationReceived(NotificationMessage(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        )));
      }
    });

    emit(state.copyWith(isInitialized: true));
  }

  Future<void> _onTokenReceived(
    FcmTokenReceived event,
    Emitter<FcmState> emit,
  ) async {
    emit(state.copyWith(token: event.token));

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _registerFcmTokenUseCase.register(
        token: event.token,
        platform: platform,
      );
    } catch (e) {
      debugPrint('Token registration failed: $e');
    }
  }

  void _onNotificationReceived(
    FcmNotificationReceived event,
    Emitter<FcmState> emit,
  ) {
    emit(state.copyWith(lastMessage: event.message));
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
    return super.close();
  }
}
