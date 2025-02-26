import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore 추가
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        primarySwatch: Colors.blue,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(); // 🔥 FIXED: 앱 시작 시 **온라인으로 변경**
  }

  @override
  void dispose() {
    _setUserOffline(); // 🔥 FIXED: 앱이 완전히 종료될 때 **오프라인으로 변경**
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _setUserOffline(); // 🔥 FIXED: 앱이 백그라운드로 가거나 종료되면 **오프라인으로 변경**
    } else if (state == AppLifecycleState.resumed) {
      _setUserOnline(); // 🔥 FIXED: 앱이 다시 열리면 **온라인으로 변경**
    }
  }

  /// ✅ Firestore에서 사용자 문서가 존재하는지 확인하고, 없으면 생성
  Future<void> _checkAndCreateUserData(User user) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          "uid": user.uid,
          "email": user.email,
          "nickname": "새 유저",
          "profileImage": "",
          "dartBoard": "다트라이브",
          "messageSetting": "all",
          "status": "online",
          "createdAt": FieldValue.serverTimestamp(),
        });

        print("✅ Firestore에 사용자 문서가 없어서 새로 생성함.");
      } else {
        print("✅ Firestore에 사용자 문서가 이미 존재함.");
      }
    } catch (e) {
      print("❌ Firestore 사용자 문서 확인 중 오류 발생: $e");
    }
  }

  /// ✅ 사용자 상태를 온라인으로 설정
  void _setUserOnline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "status": "online",
      });
    }
  }

  /// ✅ 사용자 상태를 오프라인으로 설정
  void _setUserOffline() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "status": "offline",
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage(); // ✅ 로그인되지 않으면 로그인 페이지로 이동
        }

        // ✅ Firestore 사용자 문서 확인 후 **MainPage로 이동**
        return FutureBuilder(
          future: _checkAndCreateUserData(user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const MainPage(); // ✅ 로그인 후 **MainPage**로 이동
          },
        );
      },
    );
  }
}
