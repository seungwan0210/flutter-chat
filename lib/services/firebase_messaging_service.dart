import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 알림 권한 요청
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("알림 권한 허용됨");

      // FCM 토큰 가져오기 (디바이스 등록)
      String? token = await _firebaseMessaging.getToken();
      print("FCM 토큰: $token");

      // Foreground에서 알림 수신
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      // 백그라운드 또는 앱 종료 상태에서 알림 클릭 시
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("알림 클릭됨: ${message.notification?.title}");
      });
    }
  }

  void _showNotification(RemoteMessage message) {
    var androidDetails = const AndroidNotificationDetails(
      "channel_id",
      "채팅 알림",
      importance: Importance.high,
    );

    var generalNotificationDetails = NotificationDetails(android: androidDetails);

    _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "새 메시지",
      message.notification?.body ?? "",
      generalNotificationDetails,
    );
  }
}
