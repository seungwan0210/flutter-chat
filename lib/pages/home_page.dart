import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart'; // Logger 추가
import 'profile_detail_page.dart';
import 'UserSearchPage.dart';
import 'admin_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger(); // Logger 인스턴스 추가
  String selectedBoardFilter = "전체";
  String selectedRatingFilter = "전체";
  static const int MAX_RATING = 30;

  Map<String, dynamic>? currentUserData;
  late Stream<DocumentSnapshot> profileStatsStream;

  List<String> ratingOptions = ["전체"];
  String _messageSetting = "ALL";
  String _rank = "💀";
  bool _isDiamond = false;

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
    profileStatsStream = _getProfileStatsStream();
    ratingOptions = ["전체", ...List.generate(MAX_RATING, (index) => (index + 1).toString())];
    _logger.i("HomePage initState called");
  }

  void _listenToCurrentUser() {
    String currentUserId = auth.currentUser!.uid;
    FirebaseFirestore.instance.collection("users").doc(currentUserId).snapshots().listen(
          (userDoc) {
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              currentUserData = userDoc.data() as Map<String, dynamic>;
              _messageSetting = currentUserData!["messageReceiveSetting"] ?? "ALL";
              _isDiamond = currentUserData!["isDiamond"] ?? false;
              _rank = _calculateRank(currentUserData!["totalViews"] ?? 0, _isDiamond);
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

  Stream<DocumentSnapshot> _getProfileStatsStream() {
    String currentUserId = auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection("users").doc(currentUserId).snapshots();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _logger.e("Error loading user count: ${snapshot.error}");
              return const Text("홈 (오류)", style: TextStyle(color: Colors.white));
            }
            int userCount = snapshot.hasData
                ? snapshot.data!.docs
                .where((doc) {
              Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
              bool isActive = userData["isActive"] ?? true;
              return isActive;
            })
                .length
                : 0;
            return Text("홈 ($userCount)", style: const TextStyle(color: Colors.white));
          },
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchPage()),
              );
            },
          ),
          if (currentUserData != null && currentUserData!["role"] == "admin")
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          _buildProfileStats(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          _buildMyProfile(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          _buildFilterAndSearch(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.listenToBlockedUsers(),
              builder: (context, blockedSnapshot) {
                if (!blockedSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (blockedSnapshot.hasError) {
                  _logger.e("Error loading blocked users: ${blockedSnapshot.error}");
                  return const Center(child: Text("차단 목록 로드 중 오류", style: TextStyle(color: Colors.redAccent)));
                }

                var blockedIds = blockedSnapshot.data!.map((user) => user["blockedUserId"] as String).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection("users").snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      _logger.e("Error loading user list: ${snapshot.error}");
                      return Center(
                        child: Text(
                          "사용자 목록을 불러오는 중 오류가 발생했습니다.",
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }

                    var users = snapshot.data!.docs.where((user) {
                      if (user.id == auth.currentUser!.uid) return false; // 현재 사용자 제외
                      if (blockedIds.contains(user.id)) return false; // 차단된 사용자 제외
                      Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
                      bool isActive = userData["isActive"] ?? true; // 비활성화된 사용자 제외
                      if (!isActive) return false;
                      String dartBoard = userData["dartBoard"] ?? "없음";
                      int rating = userData["rating"] ?? 0;
                      return (selectedBoardFilter == "전체" || dartBoard == selectedBoardFilter) &&
                          (selectedRatingFilter == "전체" || rating.toString() == selectedRatingFilter);
                    }).toList();

                    _logger.i("Filtered user list length: ${users.length}");
                    return _buildUserList(users);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfile() {
    if (currentUserData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    bool isOnline = currentUserData!["status"] == "online";
    String nickname = currentUserData!["nickname"] ?? "닉네임 없음";
    String messageSetting = currentUserData!["messageReceiveSetting"] ?? "전체 허용";
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
            _buildProfileImage(mainProfileImage, profileImages, isOnline, _rank),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    "홈샵: ${currentUserData!["homeShop"] ?? "없음"}",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    "${currentUserData!["dartBoard"] ?? "없음"} | 레이팅: ${currentUserData!["rating"] ?? 0}",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    "메시지 설정: $messageSetting",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    return ListView(
      children: [
        _buildUserSection("온라인 유저", users.where((user) => user["status"] == "online").toList()),
        const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
        _buildUserSection("오프라인 유저", users.where((user) => user["status"] == "offline").toList()),
      ],
    );
  }

  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        ...users.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    String currentUserId = auth.currentUser!.uid;
    bool isOnline = user["status"] == "online";
    Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
    String messageSetting = userData["messageReceiveSetting"] ?? "전체 허용";
    int rating = userData["rating"] ?? 0;
    int totalViews = userData["totalViews"] ?? 0;
    bool isDiamond = userData["isDiamond"] ?? false;
    String rank = _calculateRank(totalViews, isDiamond);
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
    String? mainProfileImage = userData["mainProfileImage"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        leading: _buildProfileImage(mainProfileImage, profileImages, isOnline, rank),
        title: Text(
          userData["nickname"] ?? "알 수 없는 사용자",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "홈샵: ${userData["homeShop"] ?? "없음"}",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              "${userData["dartBoard"] ?? "없음"} | 레이팅: $rating",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              "메시지 설정: $messageSetting",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        onTap: () {
          _firestoreService.incrementProfileViews(user.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetailPage(
                userId: user.id,
                nickname: userData["nickname"] ?? "알 수 없음",
                profileImages: profileImages,
                isCurrentUser: user.id == currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdownFilter(
                  selectedBoardFilter,
                  ["전체", "다트라이브", "피닉스", "그란보드", "홈보드"],
                      (newValue) => setState(() => selectedBoardFilter = newValue!),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _dropdownFilter(
                  selectedRatingFilter,
                  ratingOptions,
                      (newValue) => setState(() => selectedRatingFilter = newValue!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: profileStatsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          _logger.e("Error loading profile stats: ${snapshot.error}");
          return Center(
            child: Text(
              "통계 정보를 불러오는 중 오류가 발생했습니다.",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        var stats = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Total", "${stats["totalViews"] ?? 0}"),
              _buildStatItem("Today", "${stats["todayViews"] ?? 0}"),
              _buildStatItem("Rank", _rank),
            ],
          ),
        );
      },
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
              color: Theme.of(context).textTheme.bodyMedium?.color,
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

  Widget _dropdownFilter(String selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      onChanged: onChanged,
      items: items.isNotEmpty
          ? items.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList()
          : [const DropdownMenuItem(value: "전체", child: Text("전체"))],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
    );
  }
}