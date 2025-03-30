import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import 'package:dartschat/pages/settings/dartboard_page.dart';
import 'package:dartschat/pages/settings/rating_page.dart';
import 'package:dartschat/pages/settings/message_setting_page.dart';
import 'package:dartschat/pages/settings/friend_management_page.dart';
import 'package:dartschat/pages/settings/blocked_users_page.dart';
import 'package:dartschat/pages/settings/LogoutDialog.dart';
import 'package:dartschat/pages/settings/nickname_edit_page.dart';
import 'package:dartschat/pages/settings/homeshop_page.dart';
import 'package:dartschat/pages/settings/profile_image_page.dart';
import 'package:dartschat/pages/settings/Profile_settings_Page.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/generated/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const ProfilePage({Key? key, required this.onLocaleChange}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String _nickname = "";
  String _homeShop = "";
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  String _dartBoard = "";
  int _rating = 1;
  String _messageSetting = "";

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return _firestoreService.sanitizeProfileImage(url).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsPage(onLocaleChange: widget.onLocaleChange),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.listenToUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadingDartsCircle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.errorLoadingProfile,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          var userData = snapshot.data!;
          _nickname = userData["nickname"] ?? AppLocalizations.of(context)!.nickname;
          _homeShop = userData["homeShop"] ?? AppLocalizations.of(context)!.none;
          _dartBoard = userData["dartBoard"] ?? AppLocalizations.of(context)!.dartlive;
          _rating = userData["rating"] ?? 1;
          _messageSetting = userData["messageSetting"] ?? AppLocalizations.of(context)!.all_allowed;
          _profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
          _mainProfileImage = userData["mainProfileImage"];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 20),
                _buildProfileInfo(),
                const SizedBox(height: 30),
                _buildSettingsIcons(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileImagePage()),
        );
        if (result != null || result == null) {
          setState(() {
            _mainProfileImage = result;
          });
        }
      },
      onLongPress: () {
        List<String> validImageUrls = _profileImages
            .map((img) => img['url'] as String?)
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImagePage(
              imageUrls: validImageUrls,
              initialIndex: _mainProfileImage != null && validImageUrls.contains(_mainProfileImage)
                  ? validImageUrls.indexOf(_mainProfileImage!)
                  : 0,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        child: ClipOval(
          child: _isValidImageUrl(_mainProfileImage)
              ? Image.network(
            _mainProfileImage!,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 140,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              );
            },
          )
              : Icon(
            Icons.person,
            size: 140,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildEditableField(AppLocalizations.of(context)!.nickname, _nickname, Icons.person, () async {
          String? updatedNickname = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NicknameEditPage()),
          );
          if (updatedNickname != null) {
            setState(() => _nickname = updatedNickname);
            await _firestoreService.updateUserData({"nickname": _nickname});
          }
        }),
        _buildEditableField(AppLocalizations.of(context)!.homeShop, _homeShop, Icons.store, () async {
          String? updatedHomeShop = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeShopPage()),
          );
          if (updatedHomeShop != null) {
            setState(() => _homeShop = updatedHomeShop);
            await _firestoreService.updateUserData({"homeShop": _homeShop});
          }
        }),
        _buildEditableField(AppLocalizations.of(context)!.dartBoardLabel, _dartBoard, Icons.dashboard, () async {
          String? updatedBoard = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DartboardPage()),
          );
          if (updatedBoard != null) {
            setState(() => _dartBoard = updatedBoard);
            await _firestoreService.updateUserData({"dartBoard": _dartBoard});
          }
        }),
        _buildEditableField(AppLocalizations.of(context)!.rating, "$_rating", Icons.star, () async {
          int? updatedRating = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RatingPage()),
          );
          if (updatedRating != null) {
            setState(() => _rating = updatedRating);
            await _firestoreService.updateUserData({"rating": _rating});
          }
        }),
        _buildEditableField(AppLocalizations.of(context)!.messageSetting, _messageSetting, Icons.message, () async {
          String? updatedMessageSetting = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MessageSettingPage()),
          );
          if (updatedMessageSetting != null) {
            setState(() => _messageSetting = updatedMessageSetting);
            await _firestoreService.updateUserData({"messageSetting": _messageSetting});
          }
        }),
      ],
    );
  }

  Widget _buildSettingsIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSettingsIcon(Icons.people, AppLocalizations.of(context)!.friends, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendManagementPage()));
        }),
        _buildSettingsIcon(Icons.block, AppLocalizations.of(context)!.block, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersPage()));
        }),
        _buildSettingsIcon(Icons.logout, AppLocalizations.of(context)!.logout, () {
          showDialog(
            context: context,
            builder: (context) => LogoutDialog(firestoreService: _firestoreService),
          );
        }),
      ],
    );
  }

  Widget _buildSettingsIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(icon, size: 30, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}