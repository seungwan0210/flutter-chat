import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ダーツチャット';

  @override
  String get home => 'ホーム';

  @override
  String get friends => '友達';

  @override
  String get onlineUsers => 'オンラインユーザー';

  @override
  String get offlineUsers => 'オフラインユーザー';

  @override
  String get login => 'ログイン';

  @override
  String get profile => 'プロフィール';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get signUp => '会員登録';

  @override
  String get userNotFound => 'メールが存在しません。';

  @override
  String get wrongPassword => 'パスワードが正しくありません。';

  @override
  String get invalidEmail => 'メールの形式が正しくありません。';

  @override
  String get userDisabled => 'このアカウントは無効化されています。';

  @override
  String get loginFailed => 'ログイン失敗';

  @override
  String get chat => 'チャット';

  @override
  String get more => 'もっと見る';

  @override
  String get logout => 'ログアウト';

  @override
  String get confirmLogout => '本当にログアウトしますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get logoutFailed => 'ログアウト失敗';
}
