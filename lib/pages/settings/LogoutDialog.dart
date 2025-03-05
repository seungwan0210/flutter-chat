import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/pages/login_page.dart';
import 'package:dartschat/services/firestore_service.dart';

class LogoutDialog extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService(); // ✅ Firestore 서비스

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("로그아웃"),
      content: const Text("정말 로그아웃 하시겠습니까?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // ✅ 다이얼로그 닫기
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: () async {
            await _handleLogout(context);
          },
          child: const Text("확인"),
        ),
      ],
    );
  }

  /// ✅ 로그아웃 처리
  Future<void> _handleLogout(BuildContext context) async {
    // Firestore에 로그아웃 상태 업데이트
    await firestoreService.updateUserLogout();

    // Firebase 인증 로그아웃 처리
    await FirebaseAuth.instance.signOut();

    // 로그인 페이지로 이동 (이전 모든 페이지 스택 삭제)
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }
}
