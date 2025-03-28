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
  String get userNotFound => '邮箱不存在。';

  @override
  String get wrongPassword => '密码不正确。';

  @override
  String get invalidEmail => '邮箱格式不正确。';

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
  String get confirmLogout => '确定要退出吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get logoutFailed => '退出失败';

  @override
  String get error => '错误';

  @override
  String get errorLoadingUserData => '加载用户信息时出错';

  @override
  String get errorLoadingBlockedUsers => '加载屏蔽列表时出错';

  @override
  String get errorLoadingUserList => '加载用户列表时发生错误';

  @override
  String get errorLoadingStats => '加载统计信息时发生错误';

  @override
  String get homeShop => '主店';

  @override
  String get none => '无';

  @override
  String get rating => '评分';

  @override
  String get messageSetting => '消息设置';

  @override
  String get unknownUser => '未知用户';

  @override
  String get total => '总数';

  @override
  String get today => '今天';

  @override
  String get rank => '等级';

  @override
  String get all => '全部';

  @override
  String get dartlive => '飞镖直播';

  @override
  String get phoenix => '凤凰';

  @override
  String get granboard => '格兰板';

  @override
  String get homeboard => '家用板';

  @override
  String get all_allowed => '全部允许';

  @override
  String get favorites => '收藏';

  @override
  String get noFriendsInThisStatus => '当前没有此状态的朋友。';

  @override
  String get noFriendsAdded => '还没有添加朋友。';

  @override
  String get goAddFriends => '去添加朋友';

  @override
  String get loading => '加载中';

  @override
  String get urlLaunchFailed => 'URL打开失败';

  @override
  String get profileDetail => '个人资料详情';

  @override
  String get accountDeactivated => '此账户已被禁用。';

  @override
  String get profileSettings => '个人资料设置';

  @override
  String get todayPlaySummary => '今日游戏总结';

  @override
  String get sendMessage => '发送消息';

  @override
  String get cannotMessageDeactivated => '无法向已禁用的账户发送消息。';

  @override
  String get errorCheckingFriendStatus => '检查朋友状态时出错';

  @override
  String get errorIncreasingProfileViews => '增加个人资料浏览量时出错';

  @override
  String get errorLoadingUserInfo => '加载用户信息时出错';

  @override
  String get userInfoNotFound => '找不到用户信息。';

  @override
  String get userBlocked => '用户已被屏蔽。';

  @override
  String get blockReleased => '屏蔽已解除。';

  @override
  String get errorTogglingBlock => '屏蔽/解除屏蔽时发生错误';

  @override
  String get blockedUser => '已被屏蔽的用户。';

  @override
  String get removeFriend => '删除朋友';

  @override
  String get requested => '已请求';

  @override
  String get addFriend => '添加朋友';

  @override
  String get cannotAddDeactivated => '无法将已禁用的账户添加为朋友。';

  @override
  String get block => '屏蔽';

  @override
  String get unblock => '解除屏蔽';

  @override
  String get friendRequestSent => '已发送朋友请求。';

  @override
  String get errorSendingFriendRequest => '发送朋友请求时发生错误';

  @override
  String get friendRemoved => '朋友已删除。';

  @override
  String get errorRemovingFriend => '删除朋友时发生错误';

  @override
  String get errorLoadingBlockedStatus => '加载屏蔽状态时出错';

  @override
  String get notRegistered => '未注册';

  @override
  String get friendInfo => '朋友信息';

  @override
  String get friendInfoNotFound => '无法加载朋友信息。';

  @override
  String get errorLoadingFriendInfo => '加载朋友信息时发生错误';

  @override
  String get cannotAddDeactivatedToFavorites => '无法将已禁用的账户添加到收藏。';

  @override
  String get errorTogglingFavorite => '收藏设置失败';

  @override
  String get confirmRemoveFriend => '确定要删除朋友吗？';

  @override
  String get blockUser => '屏蔽用户';

  @override
  String get confirmBlockUser => '确定要屏蔽用户吗？屏蔽后朋友关系也将解除。';

  @override
  String get errorBlockingFriend => '屏蔽朋友失败';

  @override
  String get remove => '删除';

  @override
  String get dartBoardLabel => '飞镖板';

  @override
  String get dartBoard => '飞镖板';
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
  String get login => '登錄';

  @override
  String get profile => '個人資料';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get signUp => '註冊';

  @override
  String get userNotFound => '郵箱不存在。';

  @override
  String get wrongPassword => '密碼不正確。';

  @override
  String get invalidEmail => '郵箱格式不正確。';

  @override
  String get userDisabled => '此帳戶已被禁用。';

  @override
  String get loginFailed => '登錄失敗';

  @override
  String get chat => '聊天';

  @override
  String get more => '更多';

  @override
  String get logout => '退出';

  @override
  String get confirmLogout => '確定要退出嗎？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get logoutFailed => '退出失敗';

  @override
  String get error => '錯誤';

  @override
  String get errorLoadingUserData => '載入用戶資訊時出錯';

  @override
  String get errorLoadingBlockedUsers => '載入屏蔽列表時出錯';

  @override
  String get errorLoadingUserList => '載入用戶列表時發生錯誤';

  @override
  String get errorLoadingStats => '載入統計資訊時發生錯誤';

  @override
  String get homeShop => '主店';

  @override
  String get none => '無';

  @override
  String get rating => '評分';

  @override
  String get messageSetting => '訊息設置';

  @override
  String get unknownUser => '未知用戶';

  @override
  String get total => '總數';

  @override
  String get today => '今天';

  @override
  String get rank => '等級';

  @override
  String get all => '全部';

  @override
  String get dartlive => '飛鏢直播';

  @override
  String get phoenix => '鳳凰';

  @override
  String get granboard => '格蘭板';

  @override
  String get homeboard => '家用板';

  @override
  String get all_allowed => '全部允許';

  @override
  String get favorites => '收藏';

  @override
  String get noFriendsInThisStatus => '目前沒有此狀態的朋友。';

  @override
  String get noFriendsAdded => '還沒有添加朋友。';

  @override
  String get goAddFriends => '去添加朋友';

  @override
  String get loading => '載入中';

  @override
  String get urlLaunchFailed => 'URL打開失敗';

  @override
  String get profileDetail => '個人資料詳情';

  @override
  String get accountDeactivated => '此帳戶已被禁用。';

  @override
  String get profileSettings => '個人資料設置';

  @override
  String get todayPlaySummary => '今日遊戲總結';

  @override
  String get sendMessage => '發送訊息';

  @override
  String get cannotMessageDeactivated => '無法向已禁用的帳戶發送訊息。';

  @override
  String get errorCheckingFriendStatus => '檢查朋友狀態時出錯';

  @override
  String get errorIncreasingProfileViews => '增加個人資料瀏覽量時出錯';

  @override
  String get errorLoadingUserInfo => '載入用戶資訊時出錯';

  @override
  String get userInfoNotFound => '找不到用戶資訊。';

  @override
  String get userBlocked => '用戶已被屏蔽。';

  @override
  String get blockReleased => '屏蔽已解除。';

  @override
  String get errorTogglingBlock => '屏蔽/解除屏蔽時發生錯誤';

  @override
  String get blockedUser => '已被屏蔽的用戶。';

  @override
  String get removeFriend => '刪除朋友';

  @override
  String get requested => '已請求';

  @override
  String get addFriend => '添加朋友';

  @override
  String get cannotAddDeactivated => '無法將已禁用的帳戶添加為朋友。';

  @override
  String get block => '屏蔽';

  @override
  String get unblock => '解除屏蔽';

  @override
  String get friendRequestSent => '已發送朋友請求。';

  @override
  String get errorSendingFriendRequest => '發送朋友請求時發生錯誤';

  @override
  String get friendRemoved => '朋友已刪除。';

  @override
  String get errorRemovingFriend => '刪除朋友時發生錯誤';

  @override
  String get errorLoadingBlockedStatus => '載入屏蔽狀態時出錯';

  @override
  String get notRegistered => '未註冊';

  @override
  String get friendInfo => '朋友資訊';

  @override
  String get friendInfoNotFound => '無法載入朋友資訊。';

  @override
  String get errorLoadingFriendInfo => '載入朋友資訊時發生錯誤';

  @override
  String get cannotAddDeactivatedToFavorites => '無法將已禁用的帳戶添加到收藏。';

  @override
  String get errorTogglingFavorite => '收藏設置失敗';

  @override
  String get confirmRemoveFriend => '確定要刪除朋友嗎？';

  @override
  String get blockUser => '屏蔽用戶';

  @override
  String get confirmBlockUser => '確定要屏蔽用戶嗎？屏蔽後朋友關係也將解除。';

  @override
  String get errorBlockingFriend => '屏蔽朋友失敗';

  @override
  String get remove => '刪除';

  @override
  String get dartBoardLabel => '飛鏢板';

  @override
  String get dartBoard => '飛鏢板';
}
