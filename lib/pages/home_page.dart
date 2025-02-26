import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String selectedBoardFilter = "전체";
  String selectedRatingFilter = "전체";
  String homeShopSearch = "";

  Map<String, dynamic>? currentUserData;
  late Stream<DocumentSnapshot> profileStatsStream;

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
    profileStatsStream = _getProfileStatsStream();
  }

  /// ✅ Firestore에서 로그인한 사용자 정보 실시간 감지
  void _listenToCurrentUser() {
    String currentUserId = auth.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists) {
        setState(() {
          currentUserData = userDoc.data() as Map<String, dynamic>;
        });
      }
    });
  }

  /// ✅ Firestore에서 프로필 통계 실시간 가져오기
  Stream<DocumentSnapshot> _getProfileStatsStream() {
    String currentUserId = auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection("users")
        .doc(currentUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("홈", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          _buildProfileStats(),
          const SizedBox(height: 10),
          _buildMyProfile(),
          const SizedBox(height: 10),
          _buildFilterAndSearch(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var users = snapshot.data!.docs.where((user) {
                  if (user.id == auth.currentUser!.uid)
                    return false; // ✅ 내 정보는 제외

                  String dartBoard = user["dartBoard"] ?? "없음";
                  int rating = user.data().toString().contains('rating')
                      ? user["rating"] ?? 0
                      : 0;
                  String homeShop = user["homeShop"] ?? "없음";

                  return (selectedBoardFilter == "전체" ||
                      dartBoard == selectedBoardFilter) &&
                      (selectedRatingFilter == "전체" ||
                          rating.toString() == selectedRatingFilter) &&
                      (homeShopSearch.isEmpty ||
                          homeShop.toLowerCase().contains(
                              homeShopSearch.toLowerCase()));
                }).toList();

                return _buildUserList(users);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ **내 프로필 UI (온/오프라인 아이콘 추가, 카드 제거)**
  Widget _buildMyProfile() {
    if (currentUserData == null) return const Center(child: CircularProgressIndicator());

    bool isOnline = currentUserData!["status"] == "online";

    // ✅ 닉네임 필드 확인 후 기본값 설정
    String nickname = currentUserData!.containsKey("nickname") && currentUserData!["nickname"] != null
        ? currentUserData!["nickname"]
        : "닉네임 없음";

    print("🔥 내 정보 - 닉네임 확인: $nickname"); // ✅ 로그 추가

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: auth.currentUser!.uid,
              nickname: nickname, // ✅ 여기서 nickname 사용
              profileImage: currentUserData!["profileImage"] ?? "",
              isCurrentUser: true,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white, // ✅ 배경색 화이트 적용
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildProfileImage(currentUserData!["profileImage"], isOnline),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // ✅ 닉네임 표시
                _buildProfileDetails(currentUserData!),
              ],
            ),
          ],
        ),
      ),
    );
  }



  /// ✅ **유저 리스트 UI 추가**
  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    return ListView(
      children: [
        _buildUserSection("온라인 유저",
            users.where((user) => user["status"] == "online").toList()),
        _buildUserSection("오프라인 유저",
            users.where((user) => user["status"] == "offline").toList()),
      ],
    );
  }

  /// ✅ **유저 섹션 추가 (온라인/오프라인)**
  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...users.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  /// ✅ **유저 개별 UI 추가**
  Widget _buildUserTile(QueryDocumentSnapshot user) {
    String currentUserId = auth.currentUser!.uid;
    bool isOnline = user["status"] == "online";

    return ListTile(
      leading: _buildProfileImage(user["profileImage"], isOnline),
      title: Text(user["nickname"] ?? "알 수 없음",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: _buildProfileDetails(user.data() as Map<String, dynamic>),
      // ✅ 정상 작동

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProfileDetailPage(
                  userId: user.id,
                  nickname: user["nickname"] ?? "알 수 없음",
                  profileImage: user["profileImage"] ?? "",
                  isCurrentUser: user.id == currentUserId,
                ),
          ),
        );
      },
    );
  }

  /// ✅ **필터 & 검색 UI (카드 제거, 간격 조정)**
  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            color: Colors.white, // ✅ **배경색 화이트 적용**
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
                        ["전체", "1", "2", "3", "4", "5"],
                            (newValue) => setState(() => selectedRatingFilter = newValue!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // ✅ 필터 아래 간격 줄임
                SizedBox(
                  height: 36, // ✅ 검색창 높이 조절
                  child: TextField(
                    onChanged: (value) => setState(() => homeShopSearch = value.trim()),
                    decoration: InputDecoration(
                      labelText: "홈샵 검색",
                      labelStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2), // ✅ 필터 & 유저 목록 사이 간격 조정
        ],
      ),
    );
  }



  /// ✅ **통계 아이템 UI 추가**
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent)),
        Text(
            title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  /// ✅ **프로필 통계 UI**
  Widget _buildProfileStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: profileStatsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var stats = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("총 검색량", "${stats["totalViews"] ?? 0}"),
              _buildStatItem("오늘 검색량", "${stats["todayViews"] ?? 0}"),
              _buildStatItem("친구 수", "${stats["friendCount"] ?? 0}"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String profileImage, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: profileImage.isNotEmpty
              ? NetworkImage(profileImage)
              : null,
          child: profileImage.isEmpty
              ? const Icon(Icons.person, size: 28)
              : null,
        ),
        Positioned(bottom: 0,
            right: 0,
            child: Icon(
                Icons.circle, color: isOnline ? Colors.green : Colors.red,
                size: 12)),
      ],
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("홈샵: ${userData["homeShop"] ?? "없음"}"),
        Text("${userData["dartBoard"] ?? "없음"} | 레이팅: ${userData["rating"] ??
            0}"), // ✅ "다트보드: " 제거
        Text("메시지 설정: ${userData["messageSetting"] ?? "없음"}"),
      ],
    );
  }
}
/// ✅ **드롭다운 필터 UI 추가**
Widget _dropdownFilter(String selectedValue, List<String> items, ValueChanged<String?> onChanged) {
  return DropdownButtonFormField<String>(
    value: selectedValue,
    onChanged: onChanged,
    items: items.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
