import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ 로그인 기능 추가
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // 로그인 성공 시 user 반환
    } catch (e) {
      print("로그인 실패: $e");
      return null;
    }
  }

  // ✅ 회원가입 기능 추가
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // 회원가입 성공 시 user 반환
    } catch (e) {
      print("회원가입 실패: $e");
      return null;
    }
  }
}
