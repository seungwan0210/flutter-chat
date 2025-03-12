import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // 🔹 비밀번호 보이기/숨기기 기능
  bool _isSignUpEnabled = false; // 🔹 회원가입 버튼 활성화 상태

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isSignUpEnabled = email.contains('@') && password.isNotEmpty && password.length >= 6;
    });
  }

  Future<void> _updateUserStatus(String uid, String status) async {
    await _firestore.collection("users").doc(uid).update({"status": status});
  }

  Future<void> _createUserData(User user) async {
    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email,
      "nickname": "새 유저",
      "profileImage": "https://via.placeholder.com/150", // ✅ 기본 이미지 URL
      "dartBoard": "다트라이브",
      "messageSetting": "all",
      "status": "online", // ✅ 회원가입 후 온라인 상태로 설정
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case "email-already-in-use":
        return "이미 사용 중인 이메일입니다.";
      case "invalid-email":
        return "이메일 형식이 올바르지 않습니다.";
      case "weak-password":
        return "비밀번호가 너무 약합니다.";
      default:
        return "회원가입 실패: $code";
    }
  }

  Future<void> _signUp() async {
    if (!_isSignUpEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _createUserData(userCredential.user!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (authError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(authError.code), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("회원가입 중 오류 발생: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 에러 메시지 표시 함수
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ 테마에 따라 배경 색상
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
                    fillColor: Theme.of(context).cardColor, // ✅ 테마에 따라 입력 필드 색상
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
                    fillColor: Theme.of(context).cardColor, // ✅ 테마에 따라 입력 필드 색상
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).iconTheme.color, // ✅ 테마에 따라 아이콘 색상
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
                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ), // ✅ 로딩 UI 개선
                    ],
                  ),
                )
                    : ElevatedButton(
                  onPressed: _isSignUpEnabled ? _signUp : null, // 🔹 버튼 활성화 조건
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSignUpEnabled ? Theme.of(context).primaryColor : Colors.grey, // ✅ 테마에 따라 버튼 색상
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}