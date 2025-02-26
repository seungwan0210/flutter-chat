import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'friend_requests_page.dart';
import 'friend_management_page.dart';
import 'friend_info_page.dart';
import 'utils.dart'; // ✅ utils.dart 추가

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("친구 목록"),
        actions: [
          _friendRequestIndicator(context), // 🔹 친구 요청 아이콘 추가
          _friendManagementButton(context), // 🔹 친구 관리 버튼 추가
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView( // ✅ 오버플로우 방지
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var friends = snapshot.data!.docs;
              if (friends.isEmpty) return const Center(child: Text("추가된 친구가 없습니다."));

              return Column(
                children: friends.map((friend) {
                  String friendId = friend.id;
                  return StreamBuilder<DocumentSnapshot>(
                    stream: firestore.collection("users").doc(friendId).snapshots(),
                    builder: (context, friendSnapshot) {
                      if (!friendSnapshot.hasData) return const ListTile(title: Text("불러오는 중..."));
                      var friendData = friendSnapshot.data!;
                      return _friendTile(context, friendId, friendData);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _friendTile(BuildContext context, String friendId, DocumentSnapshot friendData) {
    String nickname = friendData["nickname"] ?? "알 수 없음"; // ✅ 닉네임 가져오기
    String profileImage = friendData["profileImage"] ?? "";
    String status = friendData["status"] ?? "offline";

    return ListTile(
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: (profileImage.isNotEmpty)
                ? NetworkImage(profileImage) // ✅ 친구의 프로필 사진이 있을 경우 사용
                : const AssetImage("assets/logo.jpg") as ImageProvider, // ✅ 없을 경우 기본 로고 표시
            child: profileImage.isEmpty
                ? const Icon(Icons.person, size: 30, color: Colors.grey) // ✅ 기본 아이콘 적용
                : null,
          ),
          _statusIndicator(status),
        ],
      ),
      title: Text(
        nickname,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onTap: () => _showFriendProfile(context, friendId, nickname), // ✅ 닉네임 추가
    );
  }


  Widget _statusIndicator(String status) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: status == "online" ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _friendRequestIndicator(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("friendRequests")
          .snapshots(),
      builder: (context, snapshot) {
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blue), // 🔹 요청이 없어도 아이콘은 보임
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendRequestsPage()));
              },
            ),
            if (requestCount > 0) // 🔥 요청 개수가 1 이상이면 숫자 표시
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    "$requestCount",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _friendManagementButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings, color: Colors.grey),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendManagementPage()));
      },
    );
  }

  void _showFriendProfile(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(
          receiverId: friendId, // ✅ friendId → receiverId
          receiverName: friendName, // ✅ 닉네임 추가
        ),
      ),
    );
  }
}


