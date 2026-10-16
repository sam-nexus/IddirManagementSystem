import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:odaa_mobile/core/api/api_client.dart';

/// Top-level handler required by FCM to receive background messages when
/// the app is closed. Must be @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The app is starting fresh in the background — Firebase is already
  // initialized by Firebase.initializeApp() in main() before this runs.
  debugPrint('[push] background message: ${message.messageId}');
}

/// Central service for push notifications:
///   - Requests permission (needed for Android 13+)
///   - Gets the FCM token
///   - Registers the token with the backend
///   - Handles foreground, background, and tap events
class PushService {
  PushService({required ApiClient api}) : _api = api;

  final ApiClient _api;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'odaa_general';
  static const _channelName = 'Odaa notifications';

  Future<void> initialize() async {
    // 1. Create the Android notification channel.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );

    // 2. Initialize the local notifications plugin.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // 3. Request permission (Android 13+, iOS).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[push] permission: ${settings.authorizationStatus}');

    // 4. Listen for foreground messages.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. Listen for taps that opened the app from a terminated state.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[push] launched from: ${initial.messageId}');
      // Handle navigation later, when we want to deep-link.
    }

    // 6. Listen for taps that opened the app from the background.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[push] opened from: ${msg.messageId}');
    });
  }

  /// Called after login. Registers this device's FCM token with the backend.
  Future<void> registerWithBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[push] no token available');
        return;
      }

      await _api.post<Map<String, dynamic>>(
        '/notifications/devices',
        body: {
          'fcm_token': token,
          'platform': 'android',
        },
      );
      debugPrint('[push] token registered');

      // Refresh the token if Firebase rotates it.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _api.post<Map<String, dynamic>>(
          '/notifications/devices',
          body: {'fcm_token': newToken, 'platform': 'android'},
        ).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[push] register failed: $e');
    }
  }

  /// Called on logout. Removes the token so the backend stops sending.
  Future<void> unregisterFromBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _api.delete<Map<String, dynamic>>(
        '/notifications/devices',
        query: {'token': token},
      );
    } catch (_) {}
  }

  /// Shows a local notification when a message arrives while the app is open.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}