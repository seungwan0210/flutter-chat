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
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get signUp => '新規登録';

  @override
  String get userNotFound => 'メールアドレスが存在しません。';

  @override
  String get wrongPassword => 'パスワードが正しくありません。';

  @override
  String get invalidEmail => 'メールアドレスの形式が正しくありません。';

  @override
  String get userDisabled => 'このアカウントは無効化されています。';

  @override
  String get loginFailed => 'ログインに失敗しました';

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
  String get logoutFailed => 'ログアウトに失敗しました';

  @override
  String get error => 'エラー';

  @override
  String get errorLoadingUserData => 'ユーザー情報の読み込み中にエラーが発生しました';

  @override
  String get errorLoadingBlockedUsers => 'ブロックリストの読み込み中にエラーが発生しました';

  @override
  String get errorLoadingUserList => 'ユーザー一覧の読み込み中にエラーが発生しました。';

  @override
  String get errorLoadingStats => '統計情報の読み込み中にエラーが発生しました。';

  @override
  String get homeShop => 'ホームショップ';

  @override
  String get none => 'なし';

  @override
  String get rating => 'レーティング';

  @override
  String get messageSetting => 'メッセージ設定';

  @override
  String get unknownUser => '不明なユーザー';

  @override
  String get total => '合計';

  @override
  String get today => '今日';

  @override
  String get rank => 'ランク';

  @override
  String get all => 'すべて';

  @override
  String get dartlive => 'ダートライブ';

  @override
  String get phoenix => 'フェニックス';

  @override
  String get granboard => 'グランボード';

  @override
  String get homeboard => 'ホームボード';

  @override
  String get all_allowed => 'すべてのユーザー';

  @override
  String get favorites => 'お気に入り';

  @override
  String get noFriendsInThisStatus => '現在、このステータスの友達はいません。';

  @override
  String get noFriendsAdded => 'まだ友達が追加されていません。';

  @override
  String get goAddFriends => '友達を追加しに行く';

  @override
  String get loading => '読み込み中';

  @override
  String get urlLaunchFailed => 'URLを開くのに失敗しました';

  @override
  String get profileDetail => 'プロフィール詳細';

  @override
  String get accountDeactivated => 'このアカウントは無効化されています。';

  @override
  String get profileSettings => 'プロフィール設定';

  @override
  String get todayPlaySummary => '今日のプレイサマリー';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String get cannotMessageDeactivated => '無効化されたアカウントにはメッセージを送信できません。';

  @override
  String get errorCheckingFriendStatus => '友達ステータスの確認中にエラー';

  @override
  String get errorIncreasingProfileViews => 'プロフィール閲覧数の増加中にエラー';

  @override
  String get errorLoadingUserInfo => 'ユーザー情報の読み込み中にエラー';

  @override
  String get userInfoNotFound => 'ユーザー情報が見つかりません。';

  @override
  String get userBlocked => 'ユーザーがブロックされました。';

  @override
  String get blockReleased => 'ブロックが解除されました。';

  @override
  String get errorTogglingBlock => 'ブロック/ブロック解除中にエラーが発生しました';

  @override
  String get blockedUser => 'ブロックされたユーザーです。';

  @override
  String get removeFriend => '友達を削除';

  @override
  String get requested => 'リクエスト済み';

  @override
  String get addFriend => '友達を追加';

  @override
  String get cannotAddDeactivated => '無効化されたアカウントは友達として追加できません。';

  @override
  String get block => 'ブロック';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get friendRequestSent => '友達リクエストを送信しました。';

  @override
  String get errorSendingFriendRequest => '友達リクエストの送信中にエラーが発生しました';

  @override
  String get friendRemoved => '友達が削除されました。';

  @override
  String get errorRemovingFriend => '友達の削除中にエラーが 발생しました';

  @override
  String get errorLoadingBlockedStatus => 'ブロックステータスの読み込み中にエラー';

  @override
  String get notRegistered => '未登録';

  @override
  String get friendInfo => '友達情報';

  @override
  String get friendInfoNotFound => '友達情報を読み込めません。';

  @override
  String get errorLoadingFriendInfo => '友達情報の読み込み中にエラー';

  @override
  String get cannotAddDeactivatedToFavorites => '無効化されたアカウントはお気に入りに追加できません。';

  @override
  String get errorTogglingFavorite => 'お気に入り設定に失敗しました';

  @override
  String get confirmRemoveFriend => 'この友達を削除しますか？';

  @override
  String get blockUser => 'ユーザーをブロック';

  @override
  String get confirmBlockUser => 'このユーザーをブロックしますか？ブロックすると友達関係も解除됩니다。';

  @override
  String get errorBlockingFriend => '友達のブロックに失敗しました';

  @override
  String get remove => '削除';

  @override
  String get dartBoardLabel => 'ダーツボード';

  @override
  String get dartBoard => 'ダーツボード';

  @override
  String get offlineMode => 'オフラインモード';

  @override
  String get enableOfflineMode => 'オフラインモードを有効化';

  @override
  String get offlineModeDescription => 'オフラインモードを有効にすると、他のユーザーにオフラインとして表示されます。';

  @override
  String get settingsSaved => '設定が保存されました。';

  @override
  String get errorLoadingOfflineMode => 'オフラインモード設定の読み込み中にエラー';

  @override
  String get errorSavingOfflineMode => 'オフラインモード設定の保存中にエラー';

  @override
  String get languageSettings => '言語設定';

  @override
  String get languageSettingsDescription => '言語を変更するとアプリ全体に適用されます。';

  @override
  String get newUser => '新規ユーザー';

  @override
  String get emailAlreadyInUse => 'このメールアドレスはすでに使用されています。';

  @override
  String get weakPassword => 'パスワードは6文字以上である必要があります。';

  @override
  String get signUpFailed => '新規登録に失敗しました';

  @override
  String get haveAccountLogin => 'すでにアカウントをお持ちですか？ログイン';

  @override
  String get friendSearch => '友達検索';

  @override
  String get noSearchResults => '検索結果がありません。';

  @override
  String get userSearch => 'ユーザー検索';

  @override
  String get searchHint => 'ニックネーム / ホームショップで検索';

  @override
  String get friendRequests => '友達リクエスト';

  @override
  String get noFriendRequests => '受け取った友達リクエストがありません。友達を待ってみましょう！';

  @override
  String get friendRequestAccepted => '友達リクエストを承認しました。';

  @override
  String get errorAcceptingFriendRequest => '友達リクエストの承認中にエラーが発生しました';

  @override
  String get friendRequestDeclined => '友達リクエストを拒否しました。';

  @override
  String get errorDecliningFriendRequest => '友達リクエストの拒否中にエラーが発生しました';

  @override
  String get imageLoadError => '画像読み込みエラー';

  @override
  String get errorLoadingFriendRequests => '友達リクエスト一覧の読み込み中にエラーが発生しました';

  @override
  String get cannotSendMessage => '相手がメッセージを受け取ることができません。';

  @override
  String get friendsOnlyMessage => 'このユーザーは友達からのメッセージのみを許可しています。';

  @override
  String get errorSendingMessage => 'メッセージ送信中にエラーが発生しました';

  @override
  String get errorLoadingMessages => 'メッセージの読み込み中にエラーが発生しました';

  @override
  String get noMessage => '[メッセージなし]';

  @override
  String get searchMessages => 'メッセージを検索';

  @override
  String get enterMessage => 'メッセージを入力';

  @override
  String get messageBlocked => 'メッセージをブロック';

  @override
  String get friendsOnly => '友達のみ';

  @override
  String get am => '午前';

  @override
  String get pm => '午後';

  @override
  String get errorSearching => '検索中にエラーが 발생しました';

  @override
  String get errorLoadingChatList => 'チャット一覧の読み込み中にエラーが発生しました';

  @override
  String get noChatRooms => 'チャットルームがありません';

  @override
  String get startChat => 'チャットを始めましょう';

  @override
  String get searchNickname => 'ニックネーム検索';

  @override
  String get yesterday => '昨日';

  @override
  String get updateScheduled => 'アップデート予定';

  @override
  String get comingSoon => '近日中のアップデート予定です。';

  @override
  String get tournamentInfo => 'トーナメント情報';

  @override
  String get summary => 'サマリー';

  @override
  String get writePlaySummary => 'プレイサマリーを書く';

  @override
  String get playStatusToday => '今日のプレイステータス';

  @override
  String get playedBoard => 'プレイしたボード';

  @override
  String get gamesPlayed => 'プレイしたゲーム数';

  @override
  String get bestPerformance => '今日のベストパフォーマンス';

  @override
  String get improvement => '今日の改善点';

  @override
  String get memo => '一言メモ';

  @override
  String get enterGamesPlayed => 'プレイしたゲーム数を入力してください！';

  @override
  String get enterBestPerformance => '今日のベストパフォーマンスを入力してください！';

  @override
  String get enterImprovement => '今日の改善点を入力してください！';

  @override
  String get playSummarySaved => 'プレイサマリーが保存されました！';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String get excellent => '最上';

  @override
  String get good => '中上';

  @override
  String get average => '普通';

  @override
  String get belowAverage => '中下';

  @override
  String get poor => '最下';

  @override
  String get status => 'ステータス';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get playSummaryDeleted => 'プレイサマリーが削除されました。';

  @override
  String get deleteFailed => '削除中にエラーが発生しました';

  @override
  String get save => '保存';

  @override
  String get noData => 'データなし';

  @override
  String get loadingDartsCircle => 'Darts Circle 読み込み中...';

  @override
  String get errorLoadingProfile => 'プロフィール情報の読み込み中にエラーが 발생しました。';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get blockManagement => 'ブロック管理';

  @override
  String get noBlockedUsers => 'ブロックされたユーザーがいません。';

  @override
  String get friendManagement => '友達管理';

  @override
  String get dartboardSettings => 'ダーツボード設定';

  @override
  String get errorLoadingDartboard => 'ダーツボード設定の読み込み中にエラーが 발생しました：';

  @override
  String get noDartboardList => 'ダーツボードリストを読み込めません。';

  @override
  String get errorLoadingDartboardList => 'ダーツボードリストの読み込み中にエラーが 발생しました：';

  @override
  String get dartboardSaved => 'ダーツボードが変更されました。';

  @override
  String get homeShopSettings => 'ホームショップ変更';

  @override
  String get errorLoadingHomeShop => 'ホームショップ情報の読み込み中にエラーが 발생しました：';

  @override
  String get enterHomeShop => 'ホームショップを入力してください！';

  @override
  String get invalidHomeShopLength => 'ホームショップは2～30文字で入力してください。';

  @override
  String get homeShopSaved => 'ホームショップが変更されました。';

  @override
  String get newHomeShop => '新しいホームショップ';

  @override
  String get messageSettings => 'メッセージ受信設定';

  @override
  String get errorLoadingMessageSettings => 'メッセージ設定の読み込み中にエラーが発生しました：';

  @override
  String get messageSettingsSaved => 'メッセージ受信設定が変更されました。';

  @override
  String get nicknameSettings => 'ニックネーム変更';

  @override
  String get errorLoadingNickname => 'ニックネームの読み込み中にエラーが発生しました：';

  @override
  String get enterNickname => 'ニックネ임을入力してください！';

  @override
  String get invalidNicknameFormat => 'ニックネームは2～12文字で、韓語/英語/数字/アンダースコア(_)のみ使用できます。';

  @override
  String get nicknameTaken => 'すでに使用中のニックネームです。';

  @override
  String get errorCheckingNickname => 'ニックネームの重複確認中にエラーが発生しました：';

  @override
  String get nicknameSaved => 'ニックネームが変更されました。';

  @override
  String get newNickname => '新しいニックネーム';

  @override
  String get ratingSettings => 'レーティング設定';

  @override
  String get errorLoadingRating => 'レーティング値の読み込み中にエラーが発生しました：';

  @override
  String get errorLoadingMaxRating => '最大レーティング値の読み込み中にエラーが発生しました：';

  @override
  String get ratingSaved => 'レーティングが変更されました。';

  @override
  String get profileImageSettings => 'プロフィール画像変更';

  @override
  String get errorLoadingProfileImages => 'プロフィール画像の読み込み中にエラーが 발생しました：';

  @override
  String get errorPickingImage => '画像選択中にエラーが発生しました：';

  @override
  String get imageUploaded => '画像がアップロードされました。';

  @override
  String get errorUploadingImage => '画像アップロード中にエラーが発生しました：';

  @override
  String get imageDeleted => '画像が削除されました。';

  @override
  String get errorDeletingImage => '画像削除中にエラーが発生しました：';

  @override
  String get mainImageSet => 'メイン画像が設定されました。';

  @override
  String get errorSettingMainImage => 'メイン画像設定中にエラーが発生しました：';

  @override
  String get defaultImageSet => 'デフォルト画像に設定されました。';

  @override
  String get errorSettingDefaultImage => 'デフォルト画像設定中にエラーが発生しました：';

  @override
  String get noImagesUploaded => 'まだアップロードされた画像がありません。';

  @override
  String get noDate => '日付情報なし';

  @override
  String get defaultImage => 'デフォルト画像設定';

  @override
  String get addImage => '画像追加';

  @override
  String get allMessagesRead => 'すべてのメッセージが読み込まれました。';

  @override
  String get blockedByUser => 'このユーザーにブロックされています。';

  @override
  String get messageBlockedByUser => 'このユーザーはメッセージをブロックしています。';

  @override
  String get settingUpdated => '設定が更新されました。';
}
