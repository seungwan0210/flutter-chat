import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Logger 패키지 필요
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // 비밀번호 보이기/숨기기 기능
  bool _isSignUpEnabled = false; // 회원가입 버튼 활성화 상태

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
    _logger.i("SignUpPage initState called");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logger.i("SignUpPage dispose called");
    super.dispose();
  }

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (mounted) {
      setState(() {
        _isSignUpEnabled = email.contains('@') && password.isNotEmpty && password.length >= 6;
      });
    }
  }

  Future<void> _createUserData(User user) async {
    try {
      _logger.i("Creating user data for UID: ${user.uid}");
      await _firestore.collection("users").doc(user.uid).set({
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
      });
      _logger.i("✅ 사용자 데이터 생성 완료: ${user.uid}");
    } catch (e) {
      _logger.e("❌ 사용자 데이터 생성 중 오류 발생: $e");
      throw Exception("사용자 데이터 생성 실패: $e");
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case "email-already-in-use":
        return "이미 사용 중인 이메일입니다.";
      case "invalid-email":
        return "이메일 형식이 올바르지 않습니다.";
      case "weak-password":
        return "비밀번호는 6자 이상이어야 합니다.";
      default:
        return "회원가입 실패: $code";
    }
  }

  Future<void> _signUp() async {
    if (!_isSignUpEnabled) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _logger.i("Attempting sign-up with email: ${_emailController.text.trim()}");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _createUserData(userCredential.user!);
      _logger.i("Sign-up successful, UID: ${userCredential.user!.uid}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (authError) {
      _logger.e("FirebaseAuthException: ${authError.code} - ${authError.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(authError.code), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e("Unexpected error during sign-up: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("회원가입 중 오류 발생: $e", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _logger.i("Sign-up process completed, loading: $_isLoading");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text(
                  "회원가입",
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
                    prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                    labelText: "이메일",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                    labelText: "비밀번호",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        "Darts Circle 로딩 중...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                )
                    : ElevatedButton(
                  onPressed: _isSignUpEnabled ? _signUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSignUpEnabled ? Theme.of(context).primaryColor : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "이미 계정이 있으신가요? 로그인",
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