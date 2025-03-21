import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Map<String, dynamic>? currentUserData;

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
  }

  /// Firestore에서 로그인한 사용자 정보 실시간 감지
  void _listenToCurrentUser() {
    String currentUserId = auth.currentUser!.uid;
    firestore.collection("users").doc(currentUserId).snapshots().listen((userDoc) {
      if (userDoc.exists) {
        setState(() {
          currentUserData = userDoc.data() as Map<String, dynamic>;
        });
      }
    }, onError: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보 로드 중 오류: $e")),
      );
    });
  }

  /// 등급 계산
  String _calculateRank(int totalViews) {
    if (totalViews >= 500) return "다이아몬드";
    if (totalViews >= 200) return "플래티넘";
    if (totalViews >= 100) return "골드";
    if (totalViews >= 50) return "실버";
    return "브론즈";
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("친구 (오류)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black));
            }
            int friendCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text("친구 ($friendCount)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black));
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _searchButton(context),
          _friendRequestIndicator(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildMyProfile(),
            const SizedBox(height: 10),
            // 다트라이브 배너
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => _launchURL(context, 'https://www.dartslive.com/kr/'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                        offset: const Offset(2, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/dartslive.webp'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // 즐겨찾기 섹션
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("users").doc(currentUserId).collection("favorites").snapshots(),
              builder: (context, favoriteSnapshot) {
                if (favoriteSnapshot.hasError) return const SizedBox();
                if (!favoriteSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                var favoriteIds = favoriteSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];
                return _buildUserSection("즐겨찾기", favoriteIds, isFavoriteSection: true);
              },
            ),
            // 친구 목록 섹션
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("users").doc(currentUserId).collection("friends").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return const Center(child: Text("친구 목록을 불러오는 중 오류가 발생했습니다.", style: TextStyle(color: Colors.redAccent)));
                }

                var friends = snapshot.data!.docs;
                if (friends.isEmpty) return _buildNoFriends();

                return StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection("users").doc(currentUserId).collection("blockedUsers").snapshots(),
                  builder: (context, blockedSnapshot) {
                    if (blockedSnapshot.hasError) return const SizedBox();
                    if (!blockedSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var blockedIds = blockedSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];
                    friends = friends.where((friend) => !blockedIds.contains(friend.id)).toList();

                    if (friends.isEmpty) return _buildNoFriends();

                    List<Map<String, dynamic>> onlineFriends = [];
                    List<Map<String, dynamic>> offlineFriends = [];
                    for (var friend in friends) {
                      var friendData = friend.data() as Map<String, dynamic>;
                      friendData['id'] = friend.id;
                      String status = friendData["status"] ?? "offline";
                      if (status == "online") {
                        onlineFriends.add(friendData);
                      } else {
                        offlineFriends.add(friendData);
                      }
                    }

                    return Column(
                      children: [
                        _buildUserSection("온라인 유저", onlineFriends.map((f) => f['id'] as String).toList()),
                        _buildUserSection("오프라인 유저", offlineFriends.map((f) => f['id'] as String).toList()),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 내 프로필 UI
  Widget _buildMyProfile() {
    if (currentUserData == null) return const Center(child: CircularProgressIndicator());

    bool isOnline = currentUserData!["status"] == "online";
    String nickname = currentUserData!["nickname"] ?? "닉네임 없음";
    String messageSetting = currentUserData!["messageReceiveSetting"] ?? "전체 허용";
    int totalViews = currentUserData!.containsKey("totalViews") ? currentUserData!["totalViews"] ?? 0 : 0;
    String rank = _calculateRank(totalViews);
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(currentUserData!["profileImages"] ?? []);
    String mainProfileImage = currentUserData!["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: auth.currentUser!.uid,
              nickname: nickname,
              profileImages: profileImages, // 객체 리스트 전달
              isCurrentUser: true,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildProfileImage(mainProfileImage, profileImages, isOnline),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("등급: $rank", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                Text("홈샵: ${currentUserData!["homeShop"] ?? "없음"}", style: const TextStyle(color: Colors.black54)),
                Text("${currentUserData!["dartBoard"] ?? "없음"} | 레이팅: ${currentUserData!.containsKey("rating") ? "${currentUserData!["rating"]}" : "0"}", style: const TextStyle(color: Colors.black54)),
                Text("메시지 설정: $messageSetting", style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 유저 섹션 (온라인/오프라인/즐겨찾기)
  Widget _buildUserSection(String title, List<String> friendIds, {bool isFavoriteSection = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "$title (${friendIds.length})",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        if (friendIds.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("현재 해당 상태의 친구가 없습니다.", style: TextStyle(color: Colors.black54)),
          )
        else
          ...friendIds.map((friendId) => StreamBuilder<DocumentSnapshot>(
            stream: firestore.collection("users").doc(friendId).snapshots(),
            builder: (context, friendSnapshot) {
              if (!friendSnapshot.hasData) return const ListTile(title: Text("로딩 중...", style: TextStyle(color: Colors.black87)));
              if (friendSnapshot.hasError) return const ListTile(title: Text("정보 로드 오류", style: TextStyle(color: Colors.black87)));
              if (!friendSnapshot.data!.exists) return const ListTile(title: Text("사용자 데이터 없음", style: TextStyle(color: Colors.black87)));

              var friendData = friendSnapshot.data!.data() as Map<String, dynamic>?;
              if (friendData == null) return const ListTile(title: Text("사용자 데이터 없음", style: TextStyle(color: Colors.black87)));

              List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(friendData["profileImages"] ?? []);
              String mainProfileImage = friendData["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");
              String nickname = friendData["nickname"] ?? "알 수 없음";
              String homeShop = friendData["homeShop"] ?? "없음";
              String dartBoard = friendData["dartBoard"] ?? "정보 없음";
              int rating = friendData.containsKey("rating") ? friendData["rating"] ?? 0 : 0;
              String messageSetting = friendData["messageReceiveSetting"] ?? "전체 허용";
              bool isOnline = friendData["status"] == "online";
              int totalViews = friendData.containsKey("totalViews") ? friendData["totalViews"] ?? 0 : 0;
              String rank = _calculateRank(totalViews);

              return Container(
                color: Colors.white,
                child: ListTile(
                  leading: _buildProfileImage(mainProfileImage, profileImages, isOnline),
                  title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("등급: $rank", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      Text("홈샵: $homeShop", style: const TextStyle(color: Colors.black54)),
                      Text("$dartBoard | 레이팅: $rating", style: const TextStyle(color: Colors.black54)),
                      Text("메시지 설정: $messageSetting", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                  onTap: () => _showFriendProfile(context, friendId, nickname, profileImages),
                ),
              );
            },
          )).toList(),
      ],
    );
  }

  Widget _buildNoFriends() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("아직 추가된 친구가 없습니다.", style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
              },
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text("친구 추가하러 가기", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.black),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendSearchPage()));
      },
    );
  }

  Widget _friendRequestIndicator(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("users").doc(auth.currentUser!.uid).collection("friendRequests").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return IconButton(icon: const Icon(Icons.error), onPressed: () {});
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.black),
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
                  backgroundColor: Colors.redAccent,
                  child: Text("$requestCount", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFriendProfile(BuildContext context, String friendId, String friendName, List<Map<String, dynamic>> profileImages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(
          receiverId: friendId,
          receiverName: friendName,
          receiverImages: profileImages, // 객체 리스트 전달
        ),
      ),
    );
  }

  Widget _buildProfileImage(String mainProfileImage, List<Map<String, dynamic>> profileImages, bool isOnline) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (profileImages.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    imageUrls: profileImages.map((img) => img['url'] as String).toList(),
                    initialIndex: profileImages.indexWhere((img) => img['url'] == mainProfileImage),
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            radius: 28,
            backgroundImage: mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
            child: mainProfileImage.isEmpty ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
      ],
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) throw 'Could not launch $url';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL 열기 실패: $e')));
    }
  }
}

// 전체 화면 이미지 보기 페이지 (여러 장 넘겨보기 지원)
class FullScreenImagePage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                height: double.infinity,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error, color: Colors.white));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}