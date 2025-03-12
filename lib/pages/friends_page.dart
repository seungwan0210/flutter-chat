import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launcher 임포트 추가
import 'profile_detail_page.dart';
import 'friend_search_page.dart';
import 'settings/friend_requests_page.dart';
import 'friend_info_page.dart';
import '../../services/firestore_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    String currentUserId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("친구 (오류)", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor));
            }
            int friendCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text(
              "친구 ($friendCount)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
            );
          },
        ),
        actions: [
          _searchButton(context),
          _friendRequestIndicator(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 다트라이브 배너 추가
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => _launchURL(context, 'https://www.dartslive.com/kr/'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                        offset: const Offset(2, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: const AssetImage('assets/dartslive.webp'),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) => const Icon(Icons.error, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            // 즐겨찾기 섹션
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("users").doc(currentUserId).collection("favorites").snapshots(),
              builder: (context, favoriteSnapshot) {
                if (favoriteSnapshot.hasError) {
                  return const SizedBox();
                }
                var favoriteIds = favoriteSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];
                if (favoriteIds.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("즐겨찾기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    ...favoriteIds.map((friendId) => StreamBuilder<DocumentSnapshot>(
                      stream: firestore.collection("users").doc(friendId).snapshots(),
                      builder: (context, friendSnapshot) {
                        if (!friendSnapshot.hasData || friendSnapshot.hasError) {
                          return const ListTile(title: Text("정보 로드 오류"));
                        }
                        var friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                        String profileImage = _firestoreService.sanitizeProfileImage(friendData["profileImage"] ?? "") ?? "";
                        String nickname = friendData["nickname"] ?? "알 수 없음";
                        bool isOnline = friendData["status"] == "online";

                        return ListTile(
                          leading: _buildProfileImage(profileImage, isOnline),
                          title: Text(nickname, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          onTap: () => _showFriendProfile(context, friendId, nickname, profileImage),
                        );
                      },
                    )).toList(),
                  ],
                );
              },
            ),
            // 기존 친구 목록 섹션
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "친구 목록을 불러오는 중 오류가 발생했습니다.",
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                var friends = snapshot.data!.docs;

                if (friends.isEmpty) {
                  return _buildNoFriends();
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: friends.map((friend) {
                    String friendId = friend.id;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: firestore.collection("users").doc(friendId).snapshots(),
                      builder: (context, friendSnapshot) {
                        if (!friendSnapshot.hasData || !friendSnapshot.data!.exists) {
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text("알 수 없는 사용자"),
                            subtitle: Text("이 친구의 정보가 없습니다."),
                          );
                        }
                        if (friendSnapshot.hasError) {
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.error)),
                            title: Text("정보 로드 오류"),
                            subtitle: Text("친구 정보를 불러올 수 없습니다."),
                          );
                        }

                        var friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                        String profileImage = _firestoreService.sanitizeProfileImage(friendData["profileImage"] ?? "") ?? "";
                        String nickname = friendData["nickname"] ?? "알 수 없음";
                        String homeShop = friendData["homeShop"] ?? "없음";
                        String dartBoard = friendData["dartBoard"] ?? "정보 없음";
                        int rating = friendData.containsKey("rating") ? (friendData["rating"] ?? 0) : 0;
                        String messageSetting = friendData["messageReceiveSetting"] ?? "전체 허용";
                        bool isOnline = friendData["status"] == "online";

                        return ListTile(
                          leading: _buildProfileImage(profileImage, isOnline),
                          title: Text(
                            nickname,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("홈샵: $homeShop", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                              Text("$dartBoard | 레이팅: $rating", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                              Text("메시지 설정: $messageSetting", style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                            ],
                          ),
                          onTap: () => _showFriendProfile(context, friendId, nickname, profileImage),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFriends() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "아직 추가된 친구가 없습니다.",
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
            },
            icon: const Icon(Icons.search),
            label: Text(
              "친구 추가하러 가기",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.search, color: Theme.of(context).appBarTheme.foregroundColor),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
      },
    );
  }

  Widget _friendRequestIndicator(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("users").doc(auth.currentUser!.uid).collection("friendRequests").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            icon: const Icon(Icons.error),
            onPressed: () {},
          );
        }
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(Icons.person_add, color: Theme.of(context).appBarTheme.foregroundColor),
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
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: Text(
                    "$requestCount",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFriendProfile(BuildContext context, String friendId, String friendName, String friendImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(
          receiverId: friendId,
          receiverName: friendName,
          receiverImage: friendImage,
        ),
      ),
    );
  }

  Widget _buildProfileImage(String profileImage, bool isOnline) {
    String sanitizedProfileImage = _firestoreService.sanitizeProfileImage(profileImage) ?? "";
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: sanitizedProfileImage.isNotEmpty ? NetworkImage(sanitizedProfileImage) : null,
          foregroundImage: sanitizedProfileImage.isNotEmpty && !Uri.tryParse(sanitizedProfileImage)!.hasAbsolutePath
              ? const AssetImage("assets/default_profile.png") as ImageProvider
              : null,
          child: sanitizedProfileImage.isEmpty ? const Icon(Icons.person, size: 28) : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(
            Icons.circle,
            color: isOnline ? Colors.green : Colors.red,
            size: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL 열기 실패: $e')),
      );
    }
  }
}