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
import 'package:dartschat/pages/settings/LogoutDialog.dart'; // 파일 이름 확인
import 'package:dartschat/pages/settings/nickname_edit_page.dart';
import 'package:dartschat/pages/settings/homeshop_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String _nickname = "닉네임 없음";
  String _homeShop = "설정 안됨";
  String _profileImageUrl = "";
  String _dartBoard = "다트라이브";
  int _rating = 1;
  String _messageSetting = "전체 허용";

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        String fileName = 'profile_images/${_auth.currentUser!.uid}.jpg';
        Reference storageRef = _storage.ref().child(fileName);
        UploadTask uploadTask = storageRef.putData(await image.readAsBytes());
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _profileImageUrl = downloadUrl;
        });
        await _firestoreService.updateUserData({"profileImage": _profileImageUrl});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이미지 업로드 실패: $e")),
        );
      }
    }
  }

  /// URL 유효성 검사
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return _firestoreService.sanitizeProfileImage(url).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("프로필", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                    "Darts Circle 로딩 중...",
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
                "프로필 정보를 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          var userData = snapshot.data!;
          _nickname = userData["nickname"] ?? "닉네임 없음";
          _homeShop = userData["homeShop"] ?? "설정 안됨";
          _dartBoard = userData["dartBoard"] ?? "다트라이브";
          _rating = userData["rating"] ?? 1;
          _messageSetting = userData["messageSetting"] ?? "전체 허용";

          String? rawProfileImage = userData["profileImage"];
          if (rawProfileImage != null && rawProfileImage.contains('via.placeholder.com')) {
            _firestoreService.updateUserData({"profileImage": ""});
            rawProfileImage = "";
          }
          _profileImageUrl = _firestoreService.sanitizeProfileImage(rawProfileImage ?? "") ?? "";

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

  /// 프로필 이미지 변경 (에러 핸들링 강화)
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        child: ClipOval(
          child: _isValidImageUrl(_profileImageUrl)
              ? Image.network(
            _profileImageUrl,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                "assets/default_profile.png",
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              );
            },
          )
              : Image.asset(
            "assets/default_profile.png",
            width: 140,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 정보 표시 + 클릭 시 변경 가능
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

  /// 프로필 정보 섹션
  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildEditableField("닉네임", _nickname, Icons.person, () async {
          String? updatedNickname = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NicknameEditPage()),
          );
          if (updatedNickname != null) {
            setState(() => _nickname = updatedNickname);
            await _firestoreService.updateUserData({"nickname": _nickname});
          }
        }),
        _buildEditableField("홈샵", _homeShop, Icons.store, () async {
          String? updatedHomeShop = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeShopPage()),
          );
          if (updatedHomeShop != null) {
            setState(() => _homeShop = updatedHomeShop);
            await _firestoreService.updateUserData({"homeShop": _homeShop});
          }
        }),
        _buildEditableField("다트보드", _dartBoard, Icons.dashboard, () async {
          String? updatedBoard = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DartboardPage()),
          );
          if (updatedBoard != null) {
            setState(() => _dartBoard = updatedBoard);
            await _firestoreService.updateUserData({"dartBoard": _dartBoard});
          }
        }),
        _buildEditableField("레이팅", "$_rating", Icons.star, () async {
          int? updatedRating = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RatingPage()),
          );
          if (updatedRating != null) {
            setState(() => _rating = updatedRating);
            await _firestoreService.updateUserData({"rating": _rating});
          }
        }),
        _buildEditableField("메시지 설정", _messageSetting, Icons.message, () async {
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

  /// 친구 목록, 차단 목록, 로그아웃
  Widget _buildSettingsIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSettingsIcon(Icons.people, "친구 목록", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendManagementPage()));
        }),
        _buildSettingsIcon(Icons.block, "차단 목록", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersPage()));
        }),
        _buildSettingsIcon(Icons.logout, "로그아웃", () {
          showDialog(
            context: context,
            builder: (context) => LogoutDialog(firestoreService: _firestoreService),
          );
        }),
      ],
    );
  }

  /// 설정 아이콘 UI
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