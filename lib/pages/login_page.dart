import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Logger 패키지 필요
import 'main_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
    _logger.i("LoginPage initState called");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logger.i("LoginPage dispose called");
    super.dispose();
  }

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (mounted) {
      setState(() {
        _isLoginEnabled = email.contains('@') && password.isNotEmpty && password.length >= 6;
      });
    }
  }

  Future<void> _updateUserStatus(String uid, String status) async {
    _logger.i("Updating user status for UID: $uid to $status");
    await _firestore.collection("users").doc(uid).update({"status": status});
  }

  Future<void> _createUserData(User user) async {
    _logger.i("Creating user data for UID: ${user.uid}");
    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email,
      "nickname": "새 유저",
      "profileImage": "https://via.placeholder.com/150",
      "dartBoard": "다트라이브",
      "messageSetting": "all",
      "status": "online",
      "createdAt": FieldValue.serverTimestamp(),
      "blockedByCount": 0,
      "isActive": true,
    });
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case "user-not-found":
        return "이메일이 존재하지 않습니다.";
      case "wrong-password":
        return "비밀번호가 올바르지 않습니다.";
      case "invalid-email":
        return "이메일 형식이 올바르지 않습니다.";
      case "account-disabled":
        return "이 계정은 비활성화되었습니다.";
      default:
        return "로그인 실패: $code";
    }
  }

  Future<void> _login() async {
    if (!_isLoginEnabled) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _logger.i("Attempting login with email: ${_emailController.text.trim()}");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      _logger.i("Login successful, UID: $uid");

      DocumentSnapshot userDoc = await _firestore.collection("users").doc(uid).get();
      _logger.i("Fetched user document for UID: $uid, exists: ${userDoc.exists}");

      if (userDoc.exists) {
        await _updateUserStatus(uid, "online");
        _logger.i("User status updated to online");
      } else {
        await _createUserData(userCredential.user!);
        _logger.i("User document created");
      }

      _logger.i("Navigating to MainPage");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage(initialIndex: 3)),
        );
      }
    } on FirebaseAuthException catch (authError) {
      _logger.e("FirebaseAuthException: ${authError.code} - ${authError.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(authError.code))),
        );
      }
    } catch (e) {
      _logger.e("Unexpected error during login: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 중 오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _logger.i("Login process completed, loading: $_isLoading");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  'assets/logo.jpg',
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Darts Circle",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "이메일",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _isLoginEnabled ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoginEnabled ? Colors.blueAccent : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "로그인",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "회원가입",
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}