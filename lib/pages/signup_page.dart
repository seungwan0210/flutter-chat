import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange; // 필수로 변경

  const SignUpPage({super.key, required this.onLocaleChange});

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
  bool _isPasswordVisible = false;
  bool _isSignUpEnabled = false;

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
        "nickname": AppLocalizations.of(context)!.newUser, // 다국어 닉네임
        "profileImages": [],
        "mainProfileImage": "",
        "dartBoard": AppLocalizations.of(context)!.dartlive, // 다국어로 변경
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
        return AppLocalizations.of(context)!.emailAlreadyInUse;
      case "invalid-email":
        return AppLocalizations.of(context)!.invalidEmail;
      case "weak-password":
        return AppLocalizations.of(context)!.weakPassword;
      default:
        return "${AppLocalizations.of(context)!.signUpFailed}: $code";
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
          MaterialPageRoute(builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange)),
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
            content: Text("${AppLocalizations.of(context)!.signUpFailed}: $e", style: const TextStyle(color: Colors.white)),
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
    Locale currentLocale = Localizations.localeOf(context);
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
                Text(
                  AppLocalizations.of(context)!.signUp,
                  style: const TextStyle(
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
                    labelText: AppLocalizations.of(context)!.email,
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
                    labelText: AppLocalizations.of(context)!.password, // 오타 수정
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
                        "${AppLocalizations.of(context)!.appTitle} ${AppLocalizations.of(context)!.loading}...",
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
                  child: Text(
                    AppLocalizations.of(context)!.signUp,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.haveAccountLogin,
                    style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.language,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<Locale>(
                        value: currentLocale,
                        items: AppLocalizations.supportedLocales.map((locale) {
                          return DropdownMenuItem<Locale>(
                            value: locale,
                            child: Text(
                              {
                                'ko': '한국어',
                                'en': 'English',
                                'ja': '日本語',
                                'zh': '中文 (简体)',
                                'zh_TW': '中文 (繁體)',
                              }[locale.toString()] ?? locale.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null && newLocale != currentLocale) {
                            _logger.i("SignUpPage: Dropdown selected: ${newLocale.toString()}");
                            widget.onLocaleChange(newLocale);
                            setState(() {}); // UI 갱신 강제
                          }
                        },
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 2,
                        style: const TextStyle(color: Colors.black54),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}