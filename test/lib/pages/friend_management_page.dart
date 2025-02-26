import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendManagementPage extends StatelessWidget {
  const FriendManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("친구 관리"),
        centerTitle: true, // ✅ 제목 가운데 정렬
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var friends = snapshot.data!.docs;
          if (friends.isEmpty) {
            return const Center(
              child: Text(
                "관리할 친구가 없습니다.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              var friend = friends[index];
              return _friendManagementTile(context, currentUserId, friend);
            },
          );
        },
      ),
    );
  }

  Widget _friendManagementTile(BuildContext context, String currentUserId, QueryDocumentSnapshot friend) {
    String friendId = friend.id;
    String nickname = friend["nickname"] ?? "알 수 없음";
    String profileImage = friend["profileImage"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: profileImage.isNotEmpty
            ? NetworkImage(profileImage) // ✅ 친구의 프로필 사진이 있으면 사용
            : const AssetImage("assets/logo.jpg") as ImageProvider, // ✅ 없으면 기본 로고 사용
        child: profileImage.isEmpty
            ? const Icon(Icons.person, size: 30, color: Colors.grey) // ✅ 기본 아이콘 적용
            : null,
      ),
      title: Text(
        nickname,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: const Text("이 친구를 관리할 수 있습니다."),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteDialog(context, currentUserId, friendId),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String currentUserId, String friendId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("친구 삭제"),
          content: const Text("이 친구를 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _removeFriend(currentUserId, friendId);
                Navigator.pop(context);
              },
              child: const Text("삭제", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _removeFriend(String currentUserId, String friendId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection("users").doc(currentUserId).collection("friends").doc(friendId).delete();
    await firestore.collection("users").doc(friendId).collection("friends").doc(currentUserId).delete();
  }
}
