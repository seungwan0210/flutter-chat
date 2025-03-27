import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '다트챗';

  @override
  String get home => '홈';

  @override
  String get friends => '친구';

  @override
  String get onlineUsers => '온라인 유저';

  @override
  String get offlineUsers => '오프라인 유저';

  @override
  String get login => '로그인';

  @override
  String get profile => '프로필';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get signUp => '회원가입';

  @override
  String get userNotFound => '이메일이 존재하지 않습니다.';

  @override
  String get wrongPassword => '비밀번호가 올바르지 않습니다.';

  @override
  String get invalidEmail => '이메일 형식이 올바르지 않습니다.';

  @override
  String get userDisabled => '이 계정은 비활성화되었습니다.';

  @override
  String get loginFailed => '로그인 실패';

  @override
  String get chat => '채팅';

  @override
  String get more => '더보기';

  @override
  String get logout => '로그아웃';

  @override
  String get confirmLogout => '정말 로그아웃 하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get logoutFailed => '로그아웃 실패';
}
