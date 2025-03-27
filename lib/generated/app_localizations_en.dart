import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DartsChat';

  @override
  String get home => 'Home';

  @override
  String get friends => 'Friends';

  @override
  String get onlineUsers => 'Online Users';

  @override
  String get offlineUsers => 'Offline Users';

  @override
  String get login => 'Login';

  @override
  String get profile => 'Profile';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signUp => 'Sign Up';

  @override
  String get userNotFound => 'Email does not exist.';

  @override
  String get wrongPassword => 'Password is incorrect.';

  @override
  String get invalidEmail => 'Email format is invalid.';

  @override
  String get userDisabled => 'This account is disabled.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get chat => 'Chat';

  @override
  String get more => 'More';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get logoutFailed => 'Logout failed';
}
