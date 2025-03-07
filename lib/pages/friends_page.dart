import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_page.dart';
import 'friend_search_page.dart';
import 'settings/friend_requests_page.dart';
import 'friend_info_page.dart'; // ✅ FriendInfoPage import 추가

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
        title: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
          builder: (context, snapshot) {
            int friendCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text("친구 ($friendCount)", style: const TextStyle(fontWeight: FontWeight.bold));
          },
        ),
        actions: [
          _searchButton(context), // ✅ 친구 검색 버튼
          _friendRequestIndicator(context), // ✅ 친구 요청 버튼
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var friends = snapshot.data!.docs;

          if (friends.isEmpty) {
            return _buildNoFriends();
          }

          return ListView(
            children: friends.map((friend) {
              String friendId = friend.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection("users").doc(friendId).snapshots(),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData || !friendSnapshot.data!.exists) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)), // ✅ 기본 아이콘
                      title: Text("알 수 없는 사용자"),
                      subtitle: Text("이 친구의 정보가 없습니다."),
                    );
                  }

                  var friendData = friendSnapshot.data!.data() as Map<String, dynamic>;

                  String profileImage = friendData.containsKey("profileImage") ? friendData["profileImage"] : "";
                  String nickname = friendData["nickname"] ?? "알 수 없음";
                  String homeShop = friendData["homeShop"] ?? "없음";
                  String dartBoard = friendData["dartBoard"] ?? "정보 없음";
                  int rating = friendData["rating"] ?? 0;
                  String messageSetting = friendData["messageReceiveSetting"] ?? "전체 허용";
                  bool isOnline = friendData["status"] == "online";

                  return ListTile(
                    leading: _buildProfileImage(profileImage, isOnline),
                    title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("홈샵: $homeShop"),
                        Text("$dartBoard | 레이팅: $rating"),
                        Text("메시지 설정: $messageSetting", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                    onTap: () => _showFriendProfile(context, friendId, nickname,),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// ✅ 친구가 없을 때 표시되는 UI
  Widget _buildNoFriends() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("아직 추가된 친구가 없습니다.", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
            },
            icon: const Icon(Icons.search),
            label: const Text("친구 추가하러 가기"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
        ],
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

  /// ✅ 친구 프로필 페이지로 이동
  void _showFriendProfile(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(
          receiverId: friendId,  // ✅ FriendInfoPage에서 요구하는 ID
          receiverName: friendName,  // ✅ FriendInfoPage에서 요구하는 이름
        ),
      ),
    );
  }



  /// ✅ 프로필 이미지 표시 (온라인 상태 포함)
  Widget _buildProfileImage(String profileImage, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
          child: profileImage.isEmpty ? const Icon(Icons.person, size: 28) : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
      ],
    );
  }
}
