import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'blocked_users_page.dart';
import 'utils.dart'; // ✅ utils.dart 추가

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _statusMessageController = TextEditingController();

  String? _profileImageUrl;
  String _selectedDartBoard = "다트라이브";
  int _selectedRating = 1;
  bool _isOnline = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await _firestore.collection("users").doc(user.uid).get();
      Map<String, dynamic>? userDataMap = userData.data() as Map<String, dynamic>?;

      setState(() {
        _nicknameController.text = userDataMap?["nickname"] ?? "닉네임 없음";
        _statusMessageController.text = userDataMap?.containsKey("statusMessage") ?? false
            ? userDataMap!["statusMessage"]
            : "";
        _profileImageUrl = userDataMap?["profileImage"] ?? "";
        _selectedDartBoard = userDataMap?["dartBoard"] ?? "다트라이브";
        _selectedRating = userDataMap?["rating"] ?? 1;
        _isOnline = userDataMap?["status"] == "online";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = "profile_${_auth.currentUser!.uid}.jpg";

      try {
        TaskSnapshot snapshot =
        await _storage.ref().child("profile_images/$fileName").putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection("users").doc(_auth.currentUser!.uid).update({"profileImage": downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 사진이 업데이트되었습니다.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("프로필 사진 업로드 실패: $e")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).update({
        "nickname": _nicknameController.text,
        "statusMessage": _statusMessageController.text,
        "dartBoard": _selectedDartBoard,
        "rating": _selectedRating,
        "status": _isOnline ? "online" : "offline",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("프로필이 성공적으로 업데이트되었습니다.")),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _firestore.collection("users").doc(_auth.currentUser!.uid).update({
      "status": "offline",
      "fcmToken": null,
    });

    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("프로필"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), // ✅ 설정 아이콘을 더보기(...)로 변경
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 20),
              _buildSettingsSection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage, // ✅ 프로필 이미지 변경 기능
          child: CircleAvatar(
            radius: 70, // ✅ 프로필 사진 크기 확대
            backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                ? NetworkImage(_profileImageUrl!) // ✅ 프로필 사진이 있으면 네트워크 이미지 사용
                : const AssetImage("assets/logo.jpg") as ImageProvider, // ✅ 없으면 기본 로고 표시
            child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey) // ✅ 기본 아이콘 적용
                : null,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicknameController,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: "닉네임",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _statusMessageController,
          decoration: InputDecoration(
            labelText: "상태 메시지",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        ListTile(
          title: const Text("다트보드 선택"),
          trailing: DropdownButton<String>(
            value: _selectedDartBoard,
            items: ["다트라이브", "피닉스", "그란보드", "홈보드"]
                .map((board) => DropdownMenuItem(value: board, child: Text(board)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDartBoard = value!),
          ),
        ),
        ListTile(
          title: const Text("레이팅 선택"),
          trailing: DropdownButton<int>(
            value: _selectedRating,
            items: List.generate(30, (index) => index + 1)
                .map((rating) => DropdownMenuItem(value: rating, child: Text("$rating")))
                .toList(),
            onChanged: (value) => setState(() => _selectedRating = value!),
          ),
        ),
        SwitchListTile(
          title: const Text("온라인 상태 표시"),
          value: _isOnline,
          onChanged: (value) => setState(() => _isOnline = value),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        "프로필 업데이트",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }


  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text("차단 관리"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("로그아웃"),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        );
      },
    );
  }
}
