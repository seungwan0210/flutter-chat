import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:generated/l10n.dart'; // 언어팩 파일
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    Logger().e("Firebase 초기화 실패: $e");
    return;
  }
  await initializeDateFormatting('ko_KR', null);
  Logger().i("✅ intl 초기화 완료: ko_KR");

  FirestoreService firestoreService = FirestoreService();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasMigrated = prefs.getBool('hasMigratedProfileImagesToNewFormat') ?? false;

  if (!hasMigrated) {
    try {
      await firestoreService.migrateProfileImagesToNewFormat();
      await prefs.setBool('hasMigratedProfileImagesToNewFormat', true);
      Logger().i("✅ Firestore 데이터 마이그레이션 완료 (새 형식)");
    } catch (e) {
      Logger().e("Firestore 데이터 마이그레이션 실패: $e");
    }
  } else {
    Logger().i("✅ Firestore 데이터 마이그레이션 이미 실행됨 (새 형식)");
  }

  String initialLanguage = prefs.getString('language') ?? 'ko';
  runApp(DartChatApp(initialLocale: Locale(initialLanguage)));
}

class DartChatApp extends StatelessWidget {
  final Locale initialLocale;

  const DartChatApp({required this.initialLocale, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: initialLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'Darts Circle',
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
        '/': (context) => const AuthCheck(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

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
          "nickname": "새 유저",
          "profileImages": [],
          "mainProfileImage": "",
          "dartBoard": "다트라이브",
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
          SnackBar(content: Text("사용자 데이터 확인 중 오류 발생: $e")),
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
                    "Darts Circle 로딩 중...",
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
          return const LoginPage();
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
                        "Darts Circle 로딩 중...",
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
                  child: Text("오류 발생: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data!) {
              _logger.i("User is active, navigating to MainPage");
              return const MainPage();
            }

            _logger.w("User is inactive or blocked, signing out and redirecting to LoginPage");
            FirebaseAuth.instance.signOut();
            return const LoginPage();
          },
        );
      },
    );
  }
}