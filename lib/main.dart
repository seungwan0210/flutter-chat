import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // flutter_app_badger 대신 추가
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:dartschat/pages/login_page.dart';
import 'package:dartschat/pages/main_page.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

final Logger _logger = Logger();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 알림 채널 설정
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID (AndroidManifest.xml과 일치)
  'High Importance Notifications', // 이름
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  int unreadCount = int.tryParse(message.data['unreadCount'] ?? '0') ?? 0;
  await flutterLocalNotificationsPlugin.show(
    0, // 알림 ID (고유해야 함, 여기서는 단순히 0 사용)
    null, // 백그라운드에서는 제목/내용 표시 생략
    null,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        number: unreadCount, // 배지 수 설정
      ),
    ),
  );
  _logger.i("Background message received: $unreadCount unread messages");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await setupPushNotifications();
  } catch (e) {
    _logger.e("Firebase 초기화 실패: $e");
    return;
  }
  await initializeDateFormatting('ko_KR', null);
  _logger.i("✅ intl 초기화 완료: ko_KR");

  // flutter_local_notifications 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirestoreService firestoreService = FirestoreService();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasMigrated = prefs.getBool('hasMigratedProfileImagesToNewFormat') ?? false;

  if (!hasMigrated) {
    try {
      await firestoreService.migrateProfileImagesToNewFormat();
      await prefs.setBool('hasMigratedProfileImagesToNewFormat', true);
      _logger.i("✅ Firestore 데이터 마이그레이션 완료 (새 형식)");
    } catch (e) {
      _logger.e("Firestore 데이터 마이그레이션 실패: $e");
    }
  } else {
    _logger.i("✅ Firestore 데이터 마이그레이션 이미 실행됨 (새 형식)");
  }

  runApp(const DartChatApp());
}

// FCM 설정 함수
Future<void> setupPushNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 알림 권한 요청
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    _logger.i("Push notification permission granted");
  } else {
    _logger.w("Push notification permission denied");
  }

  // 백그라운드 메시지 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 포그라운드 메시지 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    int unreadCount = int.tryParse(message.data['unreadCount'] ?? '0') ?? 0;
    await flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      message.notification?.title, // FCM에서 받은 제목
      message.notification?.body, // FCM에서 받은 내용
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          number: unreadCount, // 배지 수 설정
        ),
      ),
    );
    _logger.i("Foreground message received: $unreadCount unread messages");
  });

  // 앱이 종료된 상태에서 알림 클릭 시 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _logger.i("App opened from notification: ${message.data}");
    // TODO: 채팅 페이지로 이동 로직 추가 가능
  });

  // FCM 토큰 로깅
  String? token = await messaging.getToken();
  _logger.i("FCM Token: $token");
}

class DartChatApp extends StatefulWidget {
  const DartChatApp({super.key});

  @override
  _DartChatAppState createState() => _DartChatAppState();
}

class _DartChatAppState extends State<DartChatApp> {
  Locale? _locale;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    String? countryCode = prefs.getString('countryCode');
    if (languageCode != null) {
      setState(() {
        _locale = Locale(languageCode, countryCode ?? '');
        _logger.i("Initial locale loaded: ${_locale.toString()}");
      });
    } else {
      _logger.i("No saved locale found, using device default");
    }
  }

  void _setLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    await prefs.setString('countryCode', locale.countryCode ?? '');
    setState(() {
      _locale = locale;
      _logger.i("Locale updated to: ${locale.toString()}");
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("Building MaterialApp with locale: ${_locale?.toString() ?? 'default'}");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        final resolvedLocale = _locale ?? locale ?? supportedLocales.first;
        _logger.i("Resolved locale: ${resolvedLocale.toString()}");
        return resolvedLocale;
      },
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber[700],
          unselectedItemColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: false,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        dividerColor: Colors.grey[300],
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.amber).copyWith(
          brightness: Brightness.light,
          primary: Colors.amber[700],
          secondary: Colors.black,
          error: Colors.red,
          onPrimary: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[800],
          selectedItemColor: Colors.amber[600],
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: false,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerColor: Colors.grey[700],
        cardColor: Colors.grey[800],
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.amber).copyWith(
          brightness: Brightness.dark,
          primary: Colors.amber[600],
          secondary: Colors.grey[800],
          error: Colors.redAccent,
          onPrimary: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthCheck(onLocaleChange: _setLocale),
        '/login': (context) => LoginPage(onLocaleChange: _setLocale),
        '/main': (context) => MainPage(onLocaleChange: _setLocale),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const AuthCheck({super.key, required this.onLocaleChange});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> with WidgetsBindingObserver {
  final Logger _logger = Logger();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline();
    _logger.i("AuthCheck initState called");
  }

  @override
  void dispose() {
    _setUserOffline();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _logger.i("AuthCheck dispose called");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.i("AppLifecycleState changed: $state");
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _setUserOffline();
    } else if (state == AppLifecycleState.resumed) {
      _setUserOnline();
    }
  }

  Future<void> _checkAndCreateUserData(User user) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          "uid": user.uid,
          "email": user.email,
          "nickname": AppLocalizations.of(context)!.newUser,
          "profileImages": [],
          "mainProfileImage": "",
          "dartBoard": AppLocalizations.of(context)!.dartlive,
          "messageSetting": "all",
          "status": "online",
          "createdAt": FieldValue.serverTimestamp(),
          "rating": 0,
          "friendCount": 0,
          "isOfflineMode": false,
          "blockedByCount": 0,
          "isActive": true,
          "language": "ko",
        });
        _logger.i("✅ Firestore에 사용자 문서가 없어서 새로 생성함: ${user.uid}");
      } else {
        _logger.i("✅ Firestore에 사용자 문서가 이미 존재함: ${user.uid}");
      }
    } catch (e) {
      _logger.e("❌ Firestore 사용자 문서 확인 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.error}: $e")),
        );
      }
    }
  }

  void _setUserOnline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUserStatus(true);
        _logger.i("✅ 사용자 상태를 온라인으로 설정함: ${user.uid}");
      } catch (e) {
        _logger.e("❌ 온라인 상태 업데이트 실패: $e");
      }
    }
  }

  void _setUserOffline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUserStatus(false);
        _logger.i("✅ 사용자 상태를 오프라인으로 설정함: ${user.uid}");
      } catch (e) {
        _logger.e("❌ 오프라인 상태 업데이트 실패: $e");
      }
    }
  }

  Future<bool> _checkAccountStatus(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      int blockedByCount = data.containsKey("blockedByCount") ? (data["blockedByCount"] as int? ?? 0) : 0;
      bool isActive = data.containsKey("isActive") ? (data["isActive"] as bool? ?? true) : true;

      if (blockedByCount >= 10 && isActive) {
        await FirebaseFirestore.instance.collection("users").doc(uid).update({"isActive": false});
        _logger.w("User $uid blocked 10+ times, deactivated account.");
        return false;
      }
      return isActive;
    } catch (e) {
      _logger.e("Error checking account status: $e");
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        _logger.i("AuthStateChanges stream updated, connectionState: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "${AppLocalizations.of(context)!.appTitle} ${AppLocalizations.of(context)!.loading}...",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _logger.i("No user logged in, redirecting to LoginPage");
          return LoginPage(onLocaleChange: widget.onLocaleChange);
        }

        _logger.i("User logged in, UID: ${user.uid}");
        _checkAndCreateUserData(user);
        return FutureBuilder<bool>(
          future: _checkAccountStatus(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        "${AppLocalizations.of(context)!.appTitle} ${AppLocalizations.of(context)!.loading}...",
                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              _logger.e("FutureBuilder error: ${snapshot.error}");
              return Scaffold(
                body: Center(
                  child: Text("${AppLocalizations.of(context)!.error}: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data!) {
              _logger.i("User is active, navigating to MainPage");
              return MainPage(onLocaleChange: widget.onLocaleChange);
            }

            _logger.w("User is inactive or blocked, signing out and redirecting to LoginPage");
            FirebaseAuth.instance.signOut();
            return LoginPage(onLocaleChange: widget.onLocaleChange);
          },
        );
      },
    );
  }
}