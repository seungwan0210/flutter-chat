import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/pages/friend_info_page.dart' as info;
import 'profile_detail_page.dart';
import 'package:dartschat/pages/friend_search_page.dart' as search; // ✅ 친구 검색 페이지 추가
import 'package:dartschat/pages/settings/friend_management_page.dart';
import 'package:dartschat/pages/settings/friend_requests_page.dart';

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
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          _searchButton(context), // ✅ 검색 버튼
          _friendRequestIndicator(context), // ✅ 친구 요청 버튼
          _friendManagementButton(context), // ✅ 친구 관리 버튼
          const SizedBox(width: 8),
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

                  String nickname = friendData["nickname"] ?? "알 수 없음";
                  String profileImage = friendData["profileImage"] ?? "";
                  String dartBoard = friendData["dartBoard"] ?? "정보 없음";
                  int rating = friendData.data().toString().contains("rating") ? friendData["rating"] : 0;
                  String homeShop = friendData.data().toString().contains("homeShop") ? friendData["homeShop"] : "없음";
                  String status = friendData["status"] ?? "offline";

                  return ListTile(
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                          child: profileImage.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
                        ),
                        _statusIndicator(status),
                      ],
                    ),
                    title: Text(
                      nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text("$dartBoard • 레이팅 $rating  [홈샵: $homeShop]"),
                    onTap: () => _showFriendProfile(context, friendId, nickname), // ✅ 프로필 페이지로 이동
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// ✅ 친구 검색 버튼 (수정됨)
  Widget _searchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.black87),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const search.FriendSearchPage()), // ✅ 친구 검색 페이지 이동
        );
      },
    );
  }

  /// ✅ 친구 요청 아이콘
  Widget _friendRequestIndicator(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("users").doc(auth.currentUser!.uid).collection("friendRequests").snapshots(),
      builder: (context, snapshot) {
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.black87),
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

  /// ✅ 친구 관리 버튼
  Widget _friendManagementButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings, color: Colors.black87),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendManagementPage()));
      },
    );
  }

  /// ✅ 친구 프로필 페이지로 이동 (오류 수정)
  void _showFriendProfile(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => info.FriendInfoPage(
          receiverId: friendId,
          receiverName: friendName,
        ),
      ),
    );
  }

  /// ✅ 온라인/오프라인 표시
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
}
