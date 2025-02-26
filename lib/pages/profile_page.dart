import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dartschat/pages/settings/dartboard_page.dart';
import 'package:dartschat/pages/settings/rating_page.dart';
import 'package:dartschat/pages/settings/message_setting_page.dart';
import 'package:dartschat/pages/settings/friend_management_page.dart';
import 'package:dartschat/pages/settings/blocked_users_page.dart';
import 'package:dartschat/pages/settings/LogoutDialog.dart';
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

  String _nickname = "닉네임 없음";
  String _homeShop = "설정 안됨";
  String _profileImageUrl = "";
  String _dartBoard = "다트라이브";
  int _rating = 1;
  String _messageSetting = "전체 허용";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    Map<String, dynamic>? userData = await _firestoreService.getUserData();

    if (userData != null) {
      setState(() {
        _nickname = userData["nickname"] ?? "닉네임 없음";
        _homeShop = userData["homeShop"] ?? "설정 안됨";
        _profileImageUrl = userData["profileImage"] ?? "";
        _dartBoard = userData["dartBoard"] ?? "다트라이브";
        _rating = userData["rating"] ?? 1;
        _messageSetting = userData["messageSetting"] ?? "전체 허용";
      });
    }

    setState(() => _isLoading = false);
  }

  /// ✅ **이미지 선택 및 업데이트**
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImageUrl = image.path;
      });

      await _firestoreService.updateUserData(
          {"profileImage": _profileImageUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // ✅ 밝은 배경 (화이트 계열)
      appBar: AppBar(
        title: const Text("프로필",
            style: TextStyle(
                color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, // ✅ 앱바 화이트
        elevation: 2, // ✅ 더 깔끔한 그림자 효과
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)), // ✅ 아이콘 다크 블루
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileImage(),
            const SizedBox(height: 20), // ✅ 이미지와 정보 간격 줄이기
            _buildProfileInfo(),
            const SizedBox(height: 30), // ✅ 더 넓은 간격으로 조정
            _buildSettingsIcons(),
            const SizedBox(height: 20), // ✅ 마지막 하단 여백 추가
          ],
        ),
      ),
    );
  }


  /// ✅ **프로필 이미지 변경**
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 70,
        backgroundImage: _profileImageUrl.isNotEmpty
            ? NetworkImage(_profileImageUrl) as ImageProvider
            : const AssetImage("assets/default_profile.png"),
        child: _profileImageUrl.isEmpty
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.black87)
            : null,
      ),
    );
  }

  /// ✅ **정보 표시 + 클릭 시 변경 가능 (축소 & 중앙 정렬)**
  Widget _buildEditableField(String label, String value, IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        // ✅ 패딩 조정
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // ✅ 여백 조정
        decoration: BoxDecoration(
          color: Colors.white,
          // ✅ 밝은 카드 스타일 유지
          borderRadius: BorderRadius.circular(12),
          // ✅ 모서리 둥글게
          border: Border.all(color: Color(0xFF4A90E2), width: 1.5),
          // ✅ 네온 블루 강조
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // ✅ 은은한 그림자 효과
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ 가운데 정렬
          children: [
            Icon(icon, color: Color(0xFF4A90E2), size: 24), // ✅ 네온 블루 아이콘
            const SizedBox(width: 12), // ✅ 아이콘과 텍스트 간격 조정
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center, // ✅ 텍스트 중앙 정렬
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.edit, color: Colors.grey, size: 22), // ✅ 편집 아이콘
          ],
        ),
      ),
    );
  }


  /// ✅ **프로필 정보 섹션 (수정된 버전)**
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
        _buildEditableField("메시지 설정", "전체 허용", Icons.message, () async {
          String? updatedMessageSetting = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MessageSettingPage()),
          );
          if (updatedMessageSetting != null) {
            setState(() {}); // ✅ 메시지 설정 업데이트
          }
        }),
      ],
    );
  }


  /// ✅ **친구 목록, 차단 목록, 로그아웃**
  Widget _buildSettingsIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSettingsIcon(Icons.people, "친구 목록", () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => const FriendManagementPage()));
        }),
        _buildSettingsIcon(Icons.block, "차단 목록", () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => const BlockedUsersPage()));
        }),
        _buildSettingsIcon(Icons.logout, "로그아웃", () {
          showDialog(
              context: context, builder: (context) => LogoutDialog());
        }),
      ],
    );
  }

  /// ✅ **설정 아이콘 UI (업데이트)**
  Widget _buildSettingsIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200), // ✅ 부드러운 애니메이션 효과
            curve: Curves.easeInOut,
            child: CircleAvatar(
              radius: 34, // ✅ 아이콘 크기 키움
              backgroundColor: const Color(0000), // ✅ 다크 블루 배경
              child: Icon(icon, size: 30,
                  color: const Color(0xFF00B0FF)), // ✅ 네온 블루 아이콘
            ),
          ),
          const SizedBox(height: 8), // ✅ 간격 조정
          Text(
            label,
            style: const TextStyle(
              fontSize: 15, // ✅ 가독성 향상
              fontWeight: FontWeight.w600, // ✅ 폰트 두께 추가
              color: Color(0xFF1A237E), // ✅ 다크 블루 텍스트
            ),
          ),
        ],
      ),
    );
  }
}
