import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_page.dart';
import 'friend_search_page.dart';
import 'settings/friend_management_page.dart';
import 'settings/friend_requests_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    String currentUserId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("친구", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _searchButton(context), // ✅ 친구 검색 버튼
          _friendRequestIndicator(context), // ✅ 친구 요청 버튼
          _friendManagementButton(context), // ✅ 친구 관리 버튼
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var friends = snapshot.data!.docs;

          if (friends.isEmpty) return const Center(child: Text("추가된 친구가 없습니다."));

          return ListView(
            children: friends.map((friend) {
              String friendId = friend.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection("users").doc(friendId).snapshots(),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData) return const ListTile(title: Text("불러오는 중..."));
                  var friendData = friendSnapshot.data!;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: friendData["profileImage"] != null && friendData["profileImage"].isNotEmpty
                          ? NetworkImage(friendData["profileImage"])
                          : null,
                      child: friendData["profileImage"] == null || friendData["profileImage"].isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(friendData["nickname"] ?? "알 수 없음"),
                    subtitle: Text(friendData["dartBoard"] ?? "정보 없음"),
                    onTap: () => _showFriendProfile(context, friendId, friendData["nickname"]),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// ✅ 친구 검색 버튼
  Widget _searchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
      },
    );
  }

  /// ✅ 친구 요청 버튼 (새 요청 개수 표시)
  Widget _friendRequestIndicator(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("users").doc(auth.currentUser!.uid).collection("friendRequests").snapshots(),
      builder: (context, snapshot) {
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendRequestsPage()));
              },
            ),
            if (requestCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text("$requestCount", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// ✅ 친구 관리 버튼
  Widget _friendManagementButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendManagementPage()));
      },
    );
  }

  /// ✅ 친구 프로필 페이지로 이동
  void _showFriendProfile(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailPage(
          userId: friendId,
          nickname: friendName,
          profileImage: "",
          isCurrentUser: false,
        ),
      ),
    );
  }
}
