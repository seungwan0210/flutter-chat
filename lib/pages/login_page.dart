import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'main_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const LoginPage({super.key, required this.onLocaleChange});

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
    try {
      _logger.i("Updating user status for UID: $uid to $status");
      await _firestore.collection("users").doc(uid).update({"status": status});
    } catch (e) {
      _logger.e("❌ 사용자 상태 업데이트 중 오류 발생: $e");
      throw Exception("사용자 상태 업데이트 실패: $e");
    }
  }

  Future<void> _createUserData(User user) async {
    try {
      _logger.i("Creating user data for UID: ${user.uid}");
      await _firestore.collection("users").doc(user.uid).set({
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
      });
      _logger.i("✅ 사용자 데이터 생성 완료: ${user.uid}");
    } catch (e) {
      _logger.e("❌ 사용자 데이터 생성 중 오류 발생: $e");
      throw Exception("사용자 데이터 생성 실패: $e");
    }
  }

  Future<bool> _checkAccountStatus(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        _logger.w("User document does not exist for UID: $uid");
        return false;
      }

      int blockedByCount = userDoc["blockedByCount"] ?? 0;
      bool isActive = userDoc["isActive"] ?? true;

      _logger.i("Account status for UID: $uid - blockedByCount: $blockedByCount, isActive: $isActive");

      if (blockedByCount >= 10 && isActive) {
        await _firestore.collection("users").doc(uid).update({"isActive": false});
        _logger.w("User $uid blocked 10+ times, deactivated account.");
        return false;
      }
      return isActive;
    } catch (e) {
      _logger.e("Error checking account status: $e");
      return true;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case "user-not-found":
        return AppLocalizations.of(context)!.userNotFound;
      case "wrong-password":
        return AppLocalizations.of(context)!.wrongPassword;
      case "invalid-email":
        return AppLocalizations.of(context)!.invalidEmail;
      case "user-disabled":
        return AppLocalizations.of(context)!.userDisabled;
      default:
        return "${AppLocalizations.of(context)!.loginFailed}: $code";
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

      if (!userDoc.exists) {
        await _createUserData(userCredential.user!);
      }

      bool isActive = await _checkAccountStatus(uid);
      if (!isActive) {
        await _auth.signOut();
        _logger.w("User $uid is inactive, signing out");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.userDisabled)),
          );
        }
        return;
      }

      await _updateUserStatus(uid, "online");
      _logger.i("User status updated to online");

      if (mounted) {
        _logger.i("Navigating to MainPage");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(
              initialIndex: 3,
              onLocaleChange: widget.onLocaleChange,
            ),
          ),
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
          SnackBar(content: Text("${AppLocalizations.of(context)!.loginFailed}: $e")),
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
    Locale currentLocale = Localizations.localeOf(context);
    _logger.i("Building LoginPage with current locale: ${currentLocale.toString()}");

    // 지원 로케일 목록을 로그로 확인
    _logger.i("Supported locales: ${AppLocalizations.supportedLocales.map((l) => l.toString()).toList()}");

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
                const SizedBox(height: 60),
                Image.asset(
                  'assets/logo.jpg',
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.appTitle,
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
                    labelText: AppLocalizations.of(context)!.email,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
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
                  onPressed: _isLoginEnabled ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoginEnabled ? Theme.of(context).primaryColor : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.login,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpPage(
                          onLocaleChange: widget.onLocaleChange,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.signUp,
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
                      child: DropdownButton<String>(
                        value: currentLocale.toString(), // 'ko_KR', 'en_US', 'zh_Hans', 'zh_Hant' 등
                        items: AppLocalizations.supportedLocales.map((locale) {
                          String localeString = locale.toString(); // 'ko_KR', 'zh_Hans' 등으로 고유성 보장
                          return DropdownMenuItem<String>(
                            value: localeString,
                            child: Text(
                              {
                                'ko_KR': '한국어',
                                'en_US': 'English',
                                'ja_JP': '日本語',
                                'zh': '中文 (简体)', // zh_Hans 대신 zh로 표시
                                'zh_TW': '中文 (繁體)', // zh_Hant 대신 zh_TW로 표시
                              }[localeString] ?? localeString,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newLocaleString) {
                          if (newLocaleString != null && newLocaleString != currentLocale.toString()) {
                            Locale newLocale = AppLocalizations.supportedLocales.firstWhere(
                                  (locale) => locale.toString() == newLocaleString,
                            );
                            _logger.i("LoginPage: Dropdown selected: $newLocaleString, previous: ${currentLocale.toString()}");
                            widget.onLocaleChange(newLocale);
                            setState(() {});
                          } else {
                            _logger.i("No locale change: newLocaleString is $newLocaleString and currentLocale is ${currentLocale.toString()}");
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