import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'notification_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Masukkan Public VAPID Key yang sama dengan fcm_token_card.dart.
const String webVapidKey = 'BJr8wK8XAlQRQKEOKEvgN6C_b6EVtjh-Lxv_w__iXZymwe9L9B3LF3kx9t5BjIO2PV6cITihQNng5n5hcOZzBv4';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('[FCM] Background: ${message.messageId}');
  debugPrint('[FCM] Data: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting',
    description: 'Channel notifikasi Firebase',
    importance: Importance.max,
  );

  static Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Inisialisasi khusus Android.
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      await _localNotif.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _openDetail(jsonDecode(response.payload!) as Map<String, dynamic>);
          }
        },
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Mengambil FCM Token.
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? webVapidKey : null,
      );

      debugPrint('[FCM] TOKEN: $token');
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token baru: $newToken');
    });

    // Subscribe topic hanya untuk Android.
    if (!kIsWeb) {
      await _messaging.subscribeToTopic('kelas');
    }

    // Pesan ketika aplikasi sedang terbuka.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.data}');

      if (!kIsWeb) {
        _showForegroundNotification(message);
      }
    });

    // Penanganan ketika notifikasi dibuka dari background.
    if (!kIsWeb) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _openDetail(_messageToMap(message));
      });

      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        _openDetail(_messageToMap(initialMessage));
      }

      final launchDetails = await _localNotif.getNotificationAppLaunchDetails();

      final payload = launchDetails?.notificationResponse?.payload;

      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          payload != null) {
        _openDetail(jsonDecode(payload) as Map<String, dynamic>);
      }
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(_messageToMap(message)),
    );
  }

  static Map<String, dynamic> _messageToMap(RemoteMessage message) {
    return {
      'title': message.notification?.title ?? '-',
      'body': message.notification?.body ?? '-',
      ...message.data,
    };
  }

  static void _openDetail(Map<String, dynamic> data) {
    void push() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NotificationDetailScreen(data: data)),
      );
    }

    if (navigatorKey.currentState != null) {
      push();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => push());
    }
  }
}
