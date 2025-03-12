import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/pages/login_page.dart'; // LoginPage 임포트 추가
import '../../services/firestore_service.dart';

class LogoutDialog extends StatefulWidget {
  final FirestoreService firestoreService;

  const LogoutDialog({super.key, required this.firestoreService});

  @override
  _LogoutDialogState createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _isLoggingOut = true);

    try {
      await widget.firestoreService.updateUserLogout();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그아웃 중 오류가 발생했습니다: $e")),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "로그아웃",
        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      content: _isLoggingOut
          ? const Center(child: CircularProgressIndicator())
          : Text(
        "정말 로그아웃 하시겠습니까?",
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      actions: [
        TextButton(
          onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
          child: Text(
            "취소",
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
        TextButton(
          onPressed: _isLoggingOut ? null : () => _handleLogout(context),
          child: Text(
            "확인",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}