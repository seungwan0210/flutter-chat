import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '飞镖聊天';

  @override
  String get home => '首页';

  @override
  String get friends => '朋友';

  @override
  String get onlineUsers => '在线用户';

  @override
  String get offlineUsers => '离线用户';

  @override
  String get login => '登录';

  @override
  String get profile => '个人资料';

  @override
  String get email => '电子邮件';

  @override
  String get password => '密码';

  @override
  String get signUp => '注册';

  @override
  String get userNotFound => '电子邮件不存在。';

  @override
  String get wrongPassword => '密码错误。';

  @override
  String get invalidEmail => '电子邮件格式不正确。';

  @override
  String get userDisabled => '此账户已被禁用。';

  @override
  String get loginFailed => '登录失败';

  @override
  String get chat => '聊天';

  @override
  String get more => '更多';

  @override
  String get logout => '退出';

  @override
  String get confirmLogout => '您确定要退出吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get logoutFailed => '退出失败';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appTitle => '飛鏢聊天';

  @override
  String get home => '首頁';

  @override
  String get friends => '朋友';

  @override
  String get onlineUsers => '線上用戶';

  @override
  String get offlineUsers => '離線用戶';

  @override
  String get login => '登入';

  @override
  String get profile => '個人資料';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get signUp => '註冊';

  @override
  String get userNotFound => '電子郵件不存在。';

  @override
  String get wrongPassword => '密碼錯誤。';

  @override
  String get invalidEmail => '電子郵件格式不正確。';

  @override
  String get userDisabled => '此帳戶已被禁用。';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get chat => '聊天';

  @override
  String get more => '更多';

  @override
  String get logout => '登出';

  @override
  String get confirmLogout => '您確定要登出嗎？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get logoutFailed => '登出失敗';
}
