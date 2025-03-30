import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Darts Chat'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @onlineUsers.
  ///
  /// In en, this message translates to:
  /// **'Online Users'**
  String get onlineUsers;

  /// No description provided for @offlineUsers.
  ///
  /// In en, this message translates to:
  /// **'Offline Users'**
  String get offlineUsers;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email does not exist.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is incorrect.'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Email format is incorrect.'**
  String get invalidEmail;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get userDisabled;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout Failed'**
  String get logoutFailed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLoadingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data'**
  String get errorLoadingUserData;

  /// No description provided for @errorLoadingBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading blocked users'**
  String get errorLoadingBlockedUsers;

  /// No description provided for @errorLoadingUserList.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading user list.'**
  String get errorLoadingUserList;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading stats.'**
  String get errorLoadingStats;

  /// No description provided for @homeShop.
  ///
  /// In en, this message translates to:
  /// **'Home Shop'**
  String get homeShop;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @messageSetting.
  ///
  /// In en, this message translates to:
  /// **'Message Settings'**
  String get messageSetting;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @dartlive.
  ///
  /// In en, this message translates to:
  /// **'Dartslive'**
  String get dartlive;

  /// No description provided for @phoenix.
  ///
  /// In en, this message translates to:
  /// **'Phoenix'**
  String get phoenix;

  /// No description provided for @granboard.
  ///
  /// In en, this message translates to:
  /// **'Granboard'**
  String get granboard;

  /// No description provided for @homeboard.
  ///
  /// In en, this message translates to:
  /// **'Homeboard'**
  String get homeboard;

  /// No description provided for @all_allowed.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get all_allowed;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @noFriendsInThisStatus.
  ///
  /// In en, this message translates to:
  /// **'There are no friends in this status currently.'**
  String get noFriendsInThisStatus;

  /// No description provided for @noFriendsAdded.
  ///
  /// In en, this message translates to:
  /// **'No friends have been added yet.'**
  String get noFriendsAdded;

  /// No description provided for @goAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Go add friends'**
  String get goAddFriends;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @urlLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open URL'**
  String get urlLaunchFailed;

  /// No description provided for @profileDetail.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetail;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated.'**
  String get accountDeactivated;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @todayPlaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Play Summary'**
  String get todayPlaySummary;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @cannotMessageDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Cannot send messages to a deactivated account.'**
  String get cannotMessageDeactivated;

  /// No description provided for @errorCheckingFriendStatus.
  ///
  /// In en, this message translates to:
  /// **'Error checking friend status'**
  String get errorCheckingFriendStatus;

  /// No description provided for @errorIncreasingProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Error increasing profile views'**
  String get errorIncreasingProfileViews;

  /// No description provided for @errorLoadingUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Error loading user info'**
  String get errorLoadingUserInfo;

  /// No description provided for @userInfoNotFound.
  ///
  /// In en, this message translates to:
  /// **'User info not found.'**
  String get userInfoNotFound;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User has been blocked.'**
  String get userBlocked;

  /// No description provided for @blockReleased.
  ///
  /// In en, this message translates to:
  /// **'Block has been released.'**
  String get blockReleased;

  /// No description provided for @errorTogglingBlock.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while toggling block/unblock'**
  String get errorTogglingBlock;

  /// No description provided for @blockedUser.
  ///
  /// In en, this message translates to:
  /// **'Blocked user.'**
  String get blockedUser;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get removeFriend;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// No description provided for @cannotAddDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Cannot add a deactivated account as a friend.'**
  String get cannotAddDeactivated;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get friendRequestSent;

  /// No description provided for @errorSendingFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while sending friend request'**
  String get errorSendingFriendRequest;

  /// No description provided for @friendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed.'**
  String get friendRemoved;

  /// No description provided for @errorRemovingFriend.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while removing friend'**
  String get errorRemovingFriend;

  /// No description provided for @errorLoadingBlockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Error loading blocked status'**
  String get errorLoadingBlockedStatus;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not Registered'**
  String get notRegistered;

  /// No description provided for @friendInfo.
  ///
  /// In en, this message translates to:
  /// **'Friend Info'**
  String get friendInfo;

  /// No description provided for @friendInfoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cannot load friend info.'**
  String get friendInfoNotFound;

  /// No description provided for @errorLoadingFriendInfo.
  ///
  /// In en, this message translates to:
  /// **'Error loading friend info'**
  String get errorLoadingFriendInfo;

  /// No description provided for @cannotAddDeactivatedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Cannot add a deactivated account to favorites.'**
  String get cannotAddDeactivatedToFavorites;

  /// No description provided for @errorTogglingFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle favorite'**
  String get errorTogglingFavorite;

  /// No description provided for @confirmRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove this friend?'**
  String get confirmRemoveFriend;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @confirmBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Do you want to block this user? Blocking will also remove the friend relationship.'**
  String get confirmBlockUser;

  /// No description provided for @errorBlockingFriend.
  ///
  /// In en, this message translates to:
  /// **'Failed to block friend'**
  String get errorBlockingFriend;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @dartBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dart Board'**
  String get dartBoardLabel;

  /// No description provided for @dartBoard.
  ///
  /// In en, this message translates to:
  /// **'Dart Board'**
  String get dartBoard;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @enableOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Enable Offline Mode'**
  String get enableOfflineMode;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'When offline mode is enabled, other users will see me as offline.'**
  String get offlineModeDescription;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @errorLoadingOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Error loading offline mode settings'**
  String get errorLoadingOfflineMode;

  /// No description provided for @errorSavingOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Error saving offline mode settings'**
  String get errorSavingOfflineMode;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @languageSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Changing the language will apply to the entire app.'**
  String get languageSettingsDescription;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUser;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already in use.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get weakPassword;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Failed'**
  String get signUpFailed;

  /// No description provided for @haveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccountLogin;

  /// No description provided for @friendSearch.
  ///
  /// In en, this message translates to:
  /// **'Friend Search'**
  String get friendSearch;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results.'**
  String get noSearchResults;

  /// No description provided for @userSearch.
  ///
  /// In en, this message translates to:
  /// **'User Search'**
  String get userSearch;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname / Home Shop Search'**
  String get searchHint;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequests;

  /// No description provided for @noFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'No friend requests received. Wait for friends!'**
  String get noFriendRequests;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted.'**
  String get friendRequestAccepted;

  /// No description provided for @errorAcceptingFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while accepting friend request'**
  String get errorAcceptingFriendRequest;

  /// No description provided for @friendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined.'**
  String get friendRequestDeclined;

  /// No description provided for @errorDecliningFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while declining friend request'**
  String get errorDecliningFriendRequest;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Image load error'**
  String get imageLoadError;

  /// No description provided for @errorLoadingFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading friend request list'**
  String get errorLoadingFriendRequests;

  /// No description provided for @cannotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'The other party cannot receive messages.'**
  String get cannotSendMessage;

  /// No description provided for @friendsOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Only friends can send messages.'**
  String get friendsOnlyMessage;

  /// No description provided for @errorSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while sending message'**
  String get errorSendingMessage;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading messages'**
  String get errorLoadingMessages;

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'[No Message]'**
  String get noMessage;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search conversation content'**
  String get searchMessages;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter message'**
  String get enterMessage;

  /// No description provided for @messageBlocked.
  ///
  /// In en, this message translates to:
  /// **'Message blocked'**
  String get messageBlocked;

  /// No description provided for @friendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Friends Only'**
  String get friendsOnly;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @errorSearching.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while searching'**
  String get errorSearching;

  /// No description provided for @errorLoadingChatList.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading chat list'**
  String get errorLoadingChatList;

  /// No description provided for @noChatRooms.
  ///
  /// In en, this message translates to:
  /// **'No chat rooms'**
  String get noChatRooms;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startChat;

  /// No description provided for @searchNickname.
  ///
  /// In en, this message translates to:
  /// **'Search nickname'**
  String get searchNickname;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @updateScheduled.
  ///
  /// In en, this message translates to:
  /// **'Update Scheduled'**
  String get updateScheduled;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon in a future update.'**
  String get comingSoon;

  /// No description provided for @tournamentInfo.
  ///
  /// In en, this message translates to:
  /// **'Tournament Info'**
  String get tournamentInfo;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @writePlaySummary.
  ///
  /// In en, this message translates to:
  /// **'Write Play Summary'**
  String get writePlaySummary;

  /// No description provided for @playStatusToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Play Status'**
  String get playStatusToday;

  /// No description provided for @playedBoard.
  ///
  /// In en, this message translates to:
  /// **'Played Board'**
  String get playedBoard;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// No description provided for @bestPerformance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Best Performance'**
  String get bestPerformance;

  /// No description provided for @improvement.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Improvement'**
  String get improvement;

  /// No description provided for @memo.
  ///
  /// In en, this message translates to:
  /// **'One-Line Memo'**
  String get memo;

  /// No description provided for @enterGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Please enter the number of games played!'**
  String get enterGamesPlayed;

  /// No description provided for @enterBestPerformance.
  ///
  /// In en, this message translates to:
  /// **'Please enter today\'s best performance!'**
  String get enterBestPerformance;

  /// No description provided for @enterImprovement.
  ///
  /// In en, this message translates to:
  /// **'Please enter today\'s improvement!'**
  String get enterImprovement;

  /// No description provided for @playSummarySaved.
  ///
  /// In en, this message translates to:
  /// **'Play summary saved!'**
  String get playSummarySaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @belowAverage.
  ///
  /// In en, this message translates to:
  /// **'Below Average'**
  String get belowAverage;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @playSummaryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Play summary deleted.'**
  String get playSummaryDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while deleting'**
  String get deleteFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @loadingDartsCircle.
  ///
  /// In en, this message translates to:
  /// **'Darts Circle Loading...'**
  String get loadingDartsCircle;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading profile information.'**
  String get errorLoadingProfile;

  /// No description provided for @blockManagement.
  ///
  /// In en, this message translates to:
  /// **'Block Management'**
  String get blockManagement;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'There are no blocked users.'**
  String get noBlockedUsers;

  /// No description provided for @friendManagement.
  ///
  /// In en, this message translates to:
  /// **'Friend Management'**
  String get friendManagement;

  /// No description provided for @dartboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Dartboard Settings'**
  String get dartboardSettings;

  /// No description provided for @errorLoadingDartboard.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading dartboard settings:'**
  String get errorLoadingDartboard;

  /// No description provided for @noDartboardList.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dartboard list.'**
  String get noDartboardList;

  /// No description provided for @errorLoadingDartboardList.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading dartboard list:'**
  String get errorLoadingDartboardList;

  /// No description provided for @dartboardSaved.
  ///
  /// In en, this message translates to:
  /// **'Dartboard has been updated.'**
  String get dartboardSaved;

  /// No description provided for @homeShopSettings.
  ///
  /// In en, this message translates to:
  /// **'Home Shop Settings'**
  String get homeShopSettings;

  /// No description provided for @errorLoadingHomeShop.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading home shop info:'**
  String get errorLoadingHomeShop;

  /// No description provided for @enterHomeShop.
  ///
  /// In en, this message translates to:
  /// **'Please enter a home shop!'**
  String get enterHomeShop;

  /// No description provided for @invalidHomeShopLength.
  ///
  /// In en, this message translates to:
  /// **'Home shop must be between 2 and 30 characters.'**
  String get invalidHomeShopLength;

  /// No description provided for @homeShopSaved.
  ///
  /// In en, this message translates to:
  /// **'Home shop has been updated.'**
  String get homeShopSaved;

  /// No description provided for @newHomeShop.
  ///
  /// In en, this message translates to:
  /// **'New Home Shop'**
  String get newHomeShop;

  /// No description provided for @messageSettings.
  ///
  /// In en, this message translates to:
  /// **'Message Receive Settings'**
  String get messageSettings;

  /// No description provided for @errorLoadingMessageSettings.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading message settings:'**
  String get errorLoadingMessageSettings;

  /// No description provided for @messageSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Message receive settings have been updated.'**
  String get messageSettingsSaved;

  /// No description provided for @nicknameSettings.
  ///
  /// In en, this message translates to:
  /// **'Nickname Settings'**
  String get nicknameSettings;

  /// No description provided for @errorLoadingNickname.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading nickname:'**
  String get errorLoadingNickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname!'**
  String get enterNickname;

  /// No description provided for @invalidNicknameFormat.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be 2-12 characters, using only letters, numbers, or underscore (_).'**
  String get invalidNicknameFormat;

  /// No description provided for @nicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken.'**
  String get nicknameTaken;

  /// No description provided for @errorCheckingNickname.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while checking nickname availability:'**
  String get errorCheckingNickname;

  /// No description provided for @nicknameSaved.
  ///
  /// In en, this message translates to:
  /// **'Nickname has been updated.'**
  String get nicknameSaved;

  /// No description provided for @newNickname.
  ///
  /// In en, this message translates to:
  /// **'New Nickname'**
  String get newNickname;

  /// No description provided for @ratingSettings.
  ///
  /// In en, this message translates to:
  /// **'Rating Settings'**
  String get ratingSettings;

  /// No description provided for @errorLoadingRating.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading rating value:'**
  String get errorLoadingRating;

  /// No description provided for @errorLoadingMaxRating.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading max rating value:'**
  String get errorLoadingMaxRating;

  /// No description provided for @ratingSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating has been updated.'**
  String get ratingSaved;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'nickname'**
  String get nickname;

  /// No description provided for @profileImageSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Image Settings'**
  String get profileImageSettings;

  /// No description provided for @errorLoadingProfileImages.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading profile images:'**
  String get errorLoadingProfileImages;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while picking image:'**
  String get errorPickingImage;

  /// No description provided for @imageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image has been uploaded.'**
  String get imageUploaded;

  /// No description provided for @errorUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while uploading image:'**
  String get errorUploadingImage;

  /// No description provided for @imageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Image has been deleted.'**
  String get imageDeleted;

  /// No description provided for @errorDeletingImage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting image:'**
  String get errorDeletingImage;

  /// No description provided for @mainImageSet.
  ///
  /// In en, this message translates to:
  /// **'Main image has been set.'**
  String get mainImageSet;

  /// No description provided for @errorSettingMainImage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while setting main image:'**
  String get errorSettingMainImage;

  /// No description provided for @defaultImageSet.
  ///
  /// In en, this message translates to:
  /// **'Set to default image.'**
  String get defaultImageSet;

  /// No description provided for @errorSettingDefaultImage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while setting default image:'**
  String get errorSettingDefaultImage;

  /// No description provided for @noImagesUploaded.
  ///
  /// In en, this message translates to:
  /// **'No images have been uploaded yet.'**
  String get noImagesUploaded;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date available'**
  String get noDate;

  /// No description provided for @defaultImage.
  ///
  /// In en, this message translates to:
  /// **'Set Default Image'**
  String get defaultImage;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @allMessagesRead.
  ///
  /// In en, this message translates to:
  /// **'모든 메시지가 읽혔습니다.'**
  String get allMessagesRead;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
