import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("친구 요청"),
        centerTitle: true, // ✅ 제목 가운데 정렬
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserId)
            .collection("friendRequests")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var requests = snapshot.data!.docs;
          if (requests.isEmpty) return const Center(child: Text("받은 친구 요청이 없습니다."));

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];

              return _friendRequestTile(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _friendRequestTile(BuildContext context, QueryDocumentSnapshot request) {
    String requesterId = request["requesterId"];
    String nickname = request["nickname"];
    String profileImage = request["profileImage"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: (profileImage.isNotEmpty)
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
      subtitle: const Text("친구 요청을 보냈습니다."),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _acceptFriendRequest(request.id, requesterId),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _rejectFriendRequest(request.id),
          ),
        ],
      ),
    );
  }

  void _acceptFriendRequest(String requestId, String requesterId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot requesterDoc = await firestore.collection("users").doc(requesterId).get();
    DocumentSnapshot currentUserDoc = await firestore.collection("users").doc(currentUserId).get();

    await firestore.collection("users").doc(currentUserId).collection("friends").doc(requesterId).set({
      "nickname": requesterDoc["nickname"],
      "profileImage": requesterDoc["profileImage"],
      "status": requesterDoc["status"],
      "addedAt": FieldValue.serverTimestamp(),
    });

    await firestore.collection("users").doc(requesterId).collection("friends").doc(currentUserId).set({
      "nickname": currentUserDoc["nickname"],
      "profileImage": currentUserDoc["profileImage"],
      "status": currentUserDoc["status"],
      "addedAt": FieldValue.serverTimestamp(),
    });

    await firestore.collection("users").doc(currentUserId).collection("friendRequests").doc(requestId).delete();
  }

  void _rejectFriendRequest(String requestId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection("users").doc(currentUserId).collection("friendRequests").doc(requestId).delete();
  }
}
