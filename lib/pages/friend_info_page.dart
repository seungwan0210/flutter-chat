import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class FriendInfoPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const FriendInfoPage({super.key, required this.receiverId, required this.receiverName});

  @override
  _FriendInfoPageState createState() => _FriendInfoPageState();
}

class _FriendInfoPageState extends State<FriendInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _friendData;

  @override
  void initState() {
    super.initState();
    _loadFriendInfo();
  }

  Future<void> _loadFriendInfo() async {
    try {
      DocumentSnapshot friendSnapshot =
      await _firestore.collection("users").doc(widget.receiverId).get();

      setState(() {
        _friendData = friendSnapshot.data() as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ 친구 정보 불러오기 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "친구 정보",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // ✅ 파란색 앱바 유지
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendData == null
          ? const Center(child: Text("친구 정보를 불러올 수 없습니다."))
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ 프로필 카드
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ✅ 프로필 사진
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: (_friendData!["profileImage"] != null &&
                            _friendData!["profileImage"].toString().isNotEmpty)
                            ? NetworkImage(_friendData!["profileImage"])
                            : null, // ✅ 프로필 이미지 없으면 기본 아이콘 사용
                        child: (_friendData!["profileImage"] == null ||
                            _friendData!["profileImage"].toString().isEmpty)
                            ? const Icon(Icons.person, size: 70, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // ✅ 닉네임
                      Text(
                        _friendData!["nickname"] ?? "알 수 없음",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ 사용자 정보 리스트 (홈샵, 레이팅, 다트 보드)
                      Column(
                        children: [
                          _infoTile(Icons.store, "홈샵", _friendData!["homeShop"] ?? "없음"),
                          _infoTile(Icons.star, "레이팅", _friendData!["rating"]?.toString() ?? "정보 없음"),
                          _infoTile(Icons.sports_esports, "다트 보드", _friendData!["dartBoard"] ?? "정보 없음"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ✅ 채팅 버튼 (강조)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startChat,
                  icon: const Icon(Icons.chat),
                  label: const Text("채팅하기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 사용자 정보 표시 UI
  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
