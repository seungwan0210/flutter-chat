import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';
import 'profile_detail_page.dart';
import 'friend_search_page.dart';
import 'settings/friend_requests_page.dart';
import 'friend_info_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  Map<String, dynamic>? currentUserData;

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
    _logger.i("FriendsPage initState called");
  }

  @override
  void dispose() {
    _logger.i("FriendsPage dispose called");
    super.dispose();
  }

  void _listenToCurrentUser() {
    String currentUserId = auth.currentUser!.uid;
    firestore.collection("users").doc(currentUserId).snapshots().listen(
          (userDoc) {
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              currentUserData = userDoc.data() as Map<String, dynamic>;
            });
          }
          _logger.i("Current user data updated for UID: $currentUserId");
        }
      },
      onError: (e) {
        _logger.e("Error listening to current user data: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("사용자 정보 로드 중 오류: $e")),
          );
        }
      },
    );
  }

  String _calculateRank(int totalViews, bool isDiamond) {
    if (isDiamond) return "💎";
    if (totalViews >= 20000) return "✨";
    if (totalViews >= 10000) return "⭐";
    if (totalViews >= 5000) return "🌟";
    if (totalViews >= 3000) return "🏆";
    if (totalViews >= 2500) return "🏅";
    if (totalViews >= 2200) return "🎖️";
    if (totalViews >= 1500) return "🥇";
    if (totalViews >= 500) return "🥈";
    if (totalViews >= 300) return "🥉";
    return "💀";
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.listenToFriends(),
          builder: (context, friendsSnapshot) {
            if (friendsSnapshot.hasError) {
              _logger.e("Error loading friend count: ${friendsSnapshot.error}");
              return const Text("친구 (오류)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
            }
            if (!friendsSnapshot.hasData) {
              return const Text("친구 (로딩 중)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.listenToBlockedUsers(),
              builder: (context, blockedSnapshot) {
                if (blockedSnapshot.hasError) {
                  _logger.e("Error loading blocked users: ${blockedSnapshot.error}");
                  return const Text("친구 (오류)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
                }
                if (!blockedSnapshot.hasData) {
                  return const Text("친구 (로딩 중)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
                }

                var friends = friendsSnapshot.data!;
                var blockedIds = blockedSnapshot.data!.map((user) => user["blockedUserId"] as String).toList();
                int friendCount = friends.where((friend) => !blockedIds.contains(friend["userId"])).length;
                return Text("친구 ($friendCount)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
              },
            );
          },
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _searchButton(context),
          _friendRequestIndicator(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
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
            const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            _buildMyProfile(),
            const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection("users").doc(currentUserId).collection("favorites").snapshots(),
              builder: (context, favoriteSnapshot) {
                if (favoriteSnapshot.hasError) {
                  _logger.e("Error loading favorites: ${favoriteSnapshot.error}");
                  return const SizedBox();
                }
                if (!favoriteSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                var favoriteIds = favoriteSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];
                return _buildUserSection("즐겨찾기", favoriteIds, isFavoriteSection: true);
              },
            ),
            const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.listenToFriends(),
              builder: (context, friendsSnapshot) {
                if (!friendsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (friendsSnapshot.hasError) {
                  _logger.e("Error loading friends: ${friendsSnapshot.error}");
                  return const Center(child: Text("친구 목록을 불러오는 중 오류가 발생했습니다.", style: TextStyle(color: Colors.redAccent)));
                }

                var friends = friendsSnapshot.data!;
                if (friends.isEmpty) return _buildNoFriends();

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.listenToBlockedUsers(),
                  builder: (context, blockedSnapshot) {
                    if (blockedSnapshot.hasError) {
                      _logger.e("Error loading blocked users: ${blockedSnapshot.error}");
                      return const SizedBox();
                    }
                    if (!blockedSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var blockedIds = blockedSnapshot.data!.map((user) => user["blockedUserId"] as String).toList();
                    friends = friends.where((friend) => !blockedIds.contains(friend["userId"])).toList();

                    if (friends.isEmpty) return _buildNoFriends();

                    var onlineFriendIds = friends.where((friend) => friend["status"] == "online").map((friend) => friend["userId"] as String).toList();
                    var offlineFriendIds = friends.where((friend) => friend["status"] != "online").map((friend) => friend["userId"] as String).toList();

                    _logger.i("Online friends: $onlineFriendIds, Offline friends: $offlineFriendIds");

                    return Column(
                      children: [
                        _buildUserSection("온라인 유저", onlineFriendIds),
                        const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
                        _buildUserSection("오프라인 유저", offlineFriendIds),
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

  Widget _buildMyProfile() {
    if (currentUserData == null) return const Center(child: CircularProgressIndicator());

    bool isOnline = currentUserData!["status"] == "online";
    String nickname = currentUserData!["nickname"] ?? "닉네임 없음";
    String messageSetting = currentUserData!["messageReceiveSetting"] ?? "전체 허용";
    int totalViews = currentUserData!["totalViews"] ?? 0;
    bool isDiamond = currentUserData!["isDiamond"] ?? false;
    String rank = _calculateRank(totalViews, isDiamond);
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(currentUserData!["profileImages"] ?? []);
    String? mainProfileImage = currentUserData!["mainProfileImage"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: auth.currentUser!.uid,
              nickname: nickname,
              profileImages: profileImages,
              isCurrentUser: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildProfileImage(mainProfileImage, profileImages, isOnline, rank),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    "홈샵: ${currentUserData!["homeShop"] ?? "없음"}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    "${currentUserData!["dartBoard"] ?? "없음"} | 레이팅: ${currentUserData!["rating"] ?? 0}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    "메시지 설정: $messageSetting",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(String title, List<String> friendIds, {bool isFavoriteSection = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title, // 숫자 제거
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
              if (friendSnapshot.hasError) {
                _logger.e("Error loading friend data for $friendId: ${friendSnapshot.error}");
                return const ListTile(title: Text("정보 로드 오류", style: TextStyle(color: Colors.black87)));
              }
              if (!friendSnapshot.data!.exists) return const SizedBox.shrink();

              var friendData = friendSnapshot.data!.data() as Map<String, dynamic>?;
              if (friendData == null || !(friendData["isActive"] ?? true)) return const SizedBox.shrink();

              List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(friendData["profileImages"] ?? []);
              String? mainProfileImage = friendData["mainProfileImage"];
              String nickname = friendData["nickname"] ?? "알 수 없음";
              String homeShop = friendData["homeShop"] ?? "없음";
              String dartBoard = friendData["dartBoard"] ?? "정보 없음";
              int rating = friendData["rating"] ?? 0;
              String messageSetting = friendData["messageReceiveSetting"] ?? "전체 허용";
              bool isOnline = friendData["status"] == "online";
              int totalViews = friendData["totalViews"] ?? 0;
              bool isDiamond = friendData["isDiamond"] ?? false;
              String rank = _calculateRank(totalViews, isDiamond);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  leading: _buildProfileImage(mainProfileImage, profileImages, isOnline, rank),
                  title: Text(
                    nickname,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "홈샵: $homeShop",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "$dartBoard | 레이팅: $rating",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        "메시지 설정: $messageSetting",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
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
      icon: const Icon(Icons.search, color: Colors.white),
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
          _logger.e("Error loading friend requests: ${snapshot.error}");
          return IconButton(icon: const Icon(Icons.error), onPressed: () {});
        }
        int requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
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
    _firestoreService.incrementProfileViews(friendId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(
          receiverId: friendId,
          receiverName: friendName,
          receiverImages: profileImages,
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? mainProfileImage, List<Map<String, dynamic>> profileImages, bool isOnline, String rank) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            List<String> validImageUrls = profileImages
                .map((img) => img['url'] as String?)
                .where((url) => url != null && url.isNotEmpty)
                .cast<String>()
                .toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  imageUrls: validImageUrls,
                  initialIndex: mainProfileImage != null && validImageUrls.contains(mainProfileImage)
                      ? validImageUrls.indexOf(mainProfileImage)
                      : 0,
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 28,
            backgroundImage: mainProfileImage != null && mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
            child: mainProfileImage == null || mainProfileImage.isEmpty
                ? Icon(
              Icons.person,
              size: 56,
              color: Colors.grey,
            )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              rank,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) throw 'Could not launch $url';
      _logger.i("URL launched: $url");
    } catch (e) {
      _logger.e("Error launching URL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL 열기 실패: $e')));
      }
    }
  }
}