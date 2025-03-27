import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'package:dartschat/pages/login_page.dart';
import '../../services/firestore_service.dart';

class LogoutDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final void Function(Locale)? onLocaleChange; // 언어 변경 콜백 추가

  const LogoutDialog({
    super.key,
    required this.firestoreService,
    this.onLocaleChange, // 선택적 파라미터
  });

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
          MaterialPageRoute(
            builder: (context) => LoginPage(
              onLocaleChange: widget.onLocaleChange ?? (locale) {}, // 콜백 전달, 기본값 빈 함수
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.logoutFailed ?? '로그아웃 실패'}: $e")),
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
        AppLocalizations.of(context)!.logout ?? "로그아웃", // 다국어 적용
        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      content: _isLoggingOut
          ? const Center(child: CircularProgressIndicator())
          : Text(
        AppLocalizations.of(context)!.confirmLogout ?? "정말 로그아웃 하시겠습니까?", // 다국어 적용
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      actions: [
        TextButton(
          onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.cancel ?? "취소", // 다국어 적용
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
        TextButton(
          onPressed: _isLoggingOut ? null : () => _handleLogout(context),
          child: Text(
            AppLocalizations.of(context)!.confirm ?? "확인", // 다국어 적용
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

// .arb 파일에 추가해야 할 새 키 정의
extension AppLocalizationsExtension on AppLocalizations {
  String get logout => "Logout";
  String get confirmLogout => "Are you sure you want to log out?";
  String get cancel => "Cancel";
  String get confirm => "Confirm";
  String get logoutFailed => "Logout failed";
}