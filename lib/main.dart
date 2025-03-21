import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart'; // FirestoreService 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('ko_KR', null);
  Logger().i("✅ intl 초기화 완료: ko_KR");

  // FirestoreService 인스턴스 생성
  FirestoreService firestoreService = FirestoreService();

  // 마이그레이션 실행 여부 확인
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasMigrated = prefs.getBool('hasMigratedProfileImagesToNewFormat') ?? false;

  if (!hasMigrated) {
    await firestoreService.migrateProfileImagesToNewFormat();
    await prefs.setBool('hasMigratedProfileImagesToNewFormat', true);
    Logger().i("✅ Firestore 데이터 마이그레이션 완료 (새 형식)");
  } else {
    Logger().i("✅ Firestore 데이터 마이그레이션 이미 실행됨 (새 형식)");
  }

  runApp(const DartChatApp());
}

class DartChatApp extends StatelessWidget {
  const DartChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline();
  }

  @override
  void dispose() {
    _setUserOffline();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _setUserOffline();
    } else if (state == AppLifecycleState.resumed) {
      _setUserOnline();
    }
  }

  /// Firestore에서 사용자 문서가 존재하는지 확인하고, 없으면 생성
  Future<void> _checkAndCreateUserData(User user) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          "uid": user.uid,
          "email": user.email,
          "nickname": "새 유저",
          "profileImages": [], // 새로운 형식으로 초기화
          "mainProfileImage": "", // 대표 이미지 필드 추가
          "dartBoard": "다트라이브",
          "messageSetting": "all",
          "status": "online",
          "createdAt": FieldValue.serverTimestamp(),
          "rating": 0,
          "friendCount": 0,
        });
        _logger.i("✅ Firestore에 사용자 문서가 없어서 새로 생성함.");
      } else {
        _logger.i("✅ Firestore에 사용자 문서가 이미 존재함.");
      }
    } catch (e) {
      _logger.e("❌ Firestore 사용자 문서 확인 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 데이터 확인 중 오류 발생: $e")),
      );
    }
  }

  /// 사용자 상태를 온라인으로 설정
  void _setUserOnline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "status": "online",
        });
        _logger.i("✅ 사용자 상태를 온라인으로 설정함: ${user.uid}");
      } catch (e) {
        _logger.e("❌ 온라인 상태 업데이트 실패: $e");
      }
    }
  }

  /// 사용자 상태를 오프라인으로 설정
  void _setUserOffline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "status": "offline",
        });
        _logger.i("✅ 사용자 상태를 오프라인으로 설정함: ${user.uid}");
      } catch (e) {
        _logger.e("❌ 오프라인 상태 업데이트 실패: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder(
          future: _checkAndCreateUserData(user),
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
            return const MainPage();
          },
        );
      },
    );
  }
}