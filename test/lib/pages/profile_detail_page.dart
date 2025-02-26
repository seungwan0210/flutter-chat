import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String profileImage;
  final bool isCurrentUser;

  const ProfileDetailPage({
    super.key,
    required this.userId,
    required this.nickname,
    required this.profileImage,
    required this.isCurrentUser,
  });

  @override
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isBlocked = false;
  int _rating = 0; // 다트 등급 기본값
  String _dartBoard = "정보 없음"; // 다트 보드 기본값
  String _statusMessage = ""; // 상태 메시지

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
    _loadUserInfo();
  }

  // 차단 여부 확인
  void _checkIfBlocked() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot doc = await _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .doc(widget.userId)
        .get();

    setState(() {
      _isBlocked = doc.exists;
    });
  }

  // Firestore에서 등급, 다트 보드, 상태 메시지 가져오기
  void _loadUserInfo() async {
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(widget.userId).get();
    if (userDoc.exists) {
      setState(() {
        _rating = userDoc["rating"] ?? 0;
        _dartBoard = userDoc["dartBoard"] ?? "정보 없음";
        _statusMessage = userDoc["statusMessage"] ?? "상태 메시지 없음"; // 상태 메시지 가져오기
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 사진
              CircleAvatar(
                radius: 70,
                backgroundImage: widget.profileImage.isNotEmpty
                    ? NetworkImage(widget.profileImage)
                    : const AssetImage("assets/logo.jpg") as ImageProvider,
                child: widget.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 70, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 15),

              // 닉네임
              Text(
                widget.nickname,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 상태 메시지 표시
              Text(
                "상태 메시지: $_statusMessage",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // UI 카드 (등급 & 다트 보드 정보)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.star, "등급", _rating > 0 ? "Lv. $_rating" : "미등록"),
                      _buildInfoRow(Icons.sports_esports, "다트 보드", _dartBoard),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 버튼들
              if (widget.isCurrentUser)
                _buildButton(Icons.edit, "프로필 편집", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                })
              else
                Column(
                  children: [
                    _buildButton(Icons.chat, "1:1 채팅", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverId: widget.userId,
                            receiverName: widget.nickname,
                          ),
                        ),
                      );
                    }),
                    _buildButton(Icons.person_add, "친구 추가", _sendFriendRequest),
                    _buildButton(Icons.block, _isBlocked ? "차단 해제" : "차단", _toggleBlock, color: Colors.red),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 카드 내부 정보 표시 (아이콘 + 텍스트)
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 버튼 위젯 (아이콘 + 텍스트)
  Widget _buildButton(IconData icon, String text, VoidCallback onPressed, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  void _sendFriendRequest() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot currentUserDoc = await _firestore.collection("users").doc(currentUserId).get();

    DocumentReference requestRef = _firestore
        .collection("users")
        .doc(widget.userId)
        .collection("friendRequests")
        .doc(currentUserId);

    DocumentSnapshot requestSnapshot = await requestRef.get();

    if (requestSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미 친구 요청을 보냈습니다.")),
      );
    } else {
      await requestRef.set({
        "requesterId": currentUserId,
        "nickname": currentUserDoc["nickname"],
        "profileImage": currentUserDoc["profileImage"],
        "status": "pending",
        "requestedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("친구 요청을 보냈습니다.")),
      );
    }
  }

  void _toggleBlock() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference blockRef = _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .doc(widget.userId);

    if (_isBlocked) {
      await blockRef.delete();
      setState(() {
        _isBlocked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("차단이 해제되었습니다.")),
      );
    } else {
      await blockRef.set({
        "blockedUserId": widget.userId,
        "nickname": widget.nickname,
        "profileImage": widget.profileImage,
        "blockedAt": FieldValue.serverTimestamp(),
      });
      setState(() {
        _isBlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사용자를 차단했습니다.")),
      );
    }
  }
}
