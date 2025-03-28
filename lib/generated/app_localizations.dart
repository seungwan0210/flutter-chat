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
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmail;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get userDisabled;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
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
  /// **'Logout failed'**
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
  /// **'Error occurred while loading user list'**
  String get errorLoadingUserList;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading stats'**
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
  /// **'Message Setting'**
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
  /// **'All Allowed'**
  String get all_allowed;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @noFriendsInThisStatus.
  ///
  /// In en, this message translates to:
  /// **'No friends in this status currently.'**
  String get noFriendsInThisStatus;

  /// No description provided for @noFriendsAdded.
  ///
  /// In en, this message translates to:
  /// **'No friends have been added yet.'**
  String get noFriendsAdded;

  /// No description provided for @goAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Go Add Friends'**
  String get goAddFriends;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @urlLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch URL'**
  String get urlLaunchFailed;

  /// No description provided for @profileDetail.
  ///
  /// In en, this message translates to:
  /// **'Profile Detail'**
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
  /// **'Error occurred while toggling block'**
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
  /// **'Error occurred while loading friend info'**
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
  /// **'Are you sure you want to remove this friend?'**
  String get confirmRemoveFriend;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @confirmBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? Blocking will also remove the friend relationship.'**
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
