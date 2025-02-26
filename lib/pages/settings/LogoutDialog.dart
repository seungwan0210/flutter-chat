import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/pages/login_page.dart';
import 'package:dartschat/services/firestore_service.dart'; // Firestore 서비스 가져오기

class LogoutDialog extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService(); // FirestoreService 인스턴스

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("로그아웃"),
      content: Text("로그아웃 하시겠습니까?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 다이얼로그 닫기
          },
          child: Text("취소"),
        ),
        TextButton(
          onPressed: () async {
            // Firestore에 로그아웃 상태 업데이트
            await firestoreService.updateUserLogout();

            // Firebase 인증 로그아웃 처리
            await FirebaseAuth.instance.signOut();

            // 로그인 페이지로 이동
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
            );
          },
          child: Text("확인"),
        ),
      ],
    );
  }
}
