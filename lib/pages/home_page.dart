import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_page.dart';
import '../../services/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String selectedBoardFilter = "전체";
  String selectedRatingFilter = "전체";
  String homeShopSearch = "";
  static const int MAX_RATING = 30;

  Map<String, dynamic>? currentUserData;
  late Stream<DocumentSnapshot> profileStatsStream;

  List<String> ratingOptions = ["전체"];
  String _messageSetting = "ALL";
  String _rank = "브론즈"; // 등급 추가

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
    profileStatsStream = _getProfileStatsStream();
    ratingOptions = ["전체", ...List.generate(MAX_RATING, (index) => (index + 1).toString())];
  }

  /// Firestore에서 로그인한 사용자 정보 실시간 감지
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
          _messageSetting = currentUserData!["messageReceiveSetting"] ?? "ALL";
          _rank = _calculateRank(currentUserData!["totalViews"] ?? 0); // 등급 계산
        });
      }
    }, onError: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보 로드 중 오류: $e")),
      );
    });
  }

  /// Firestore에서 프로필 통계 실시간 가져오기
  Stream<DocumentSnapshot> _getProfileStatsStream() {
    String currentUserId = auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection("users").doc(currentUserId).snapshots();
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
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                "홈 (오류)",
                style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
              );
            }
            int userCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text(
              "홈 ($userCount)",
              style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
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
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "사용자 목록을 불러오는 중 오류가 발생했습니다.",
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                var users = snapshot.data!.docs.where((user) {
                  if (user.id == auth.currentUser!.uid) return false;
                  Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
                  String dartBoard = userData["dartBoard"] ?? "없음";
                  int rating = userData.containsKey("rating") ? userData["rating"] ?? 0 : 0;
                  String homeShop = userData["homeShop"] ?? "없음";
                  return (selectedBoardFilter == "전체" || dartBoard == selectedBoardFilter) &&
                      (selectedRatingFilter == "전체" || rating.toString() == selectedRatingFilter) &&
                      (homeShopSearch.isEmpty || homeShop.toLowerCase().contains(homeShopSearch.toLowerCase()));
                }).toList();

                return _buildUserList(users);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfile() {
    if (currentUserData == null) return const Center(child: CircularProgressIndicator());

    bool isOnline = currentUserData!["status"] == "online";
    String nickname = currentUserData!["nickname"] ?? "닉네임 없음";
    String messageSetting = currentUserData!["messageReceiveSetting"] ?? "전체 허용";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: auth.currentUser!.uid,
              nickname: nickname,
              profileImage: _firestoreService.sanitizeProfileImage(currentUserData!["profileImage"] ?? "") ?? "",
              isCurrentUser: true,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildProfileImage(_firestoreService.sanitizeProfileImage(currentUserData!["profileImage"] ?? "") ?? "", isOnline),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                Text("등급: $_rank", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), // 등급 위치 조정
                Text("홈샵: ${currentUserData!["homeShop"] ?? "없음"}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                Text("${currentUserData!["dartBoard"] ?? "없음"} | 레이팅: ${currentUserData!.containsKey("rating") ? "${currentUserData!["rating"]}" : "0"}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                Text("메시지 설정: $messageSetting", style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 유저 리스트 UI
  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    return ListView(
      children: [
        _buildUserSection("온라인 유저", users.where((user) => user["status"] == "online").toList()),
        _buildUserSection("오프라인 유저", users.where((user) => user["status"] == "offline").toList()),
      ],
    );
  }

  /// 유저 섹션 (온라인/오프라인)
  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        ...users.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    String currentUserId = auth.currentUser!.uid;
    bool isOnline = user["status"] == "online";
    Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
    String messageSetting = userData.containsKey("messageReceiveSetting")
        ? userData["messageReceiveSetting"] ?? "전체 허용"
        : "전체 허용";
    int rating = userData.containsKey("rating") ? userData["rating"] ?? 0 : 0;
    int totalViews = userData.containsKey("totalViews") ? userData["totalViews"] ?? 0 : 0;
    String rank = _calculateRank(totalViews); // 등급 계산

    return ListTile(
      leading: _buildProfileImage(_firestoreService.sanitizeProfileImage(userData["profileImage"] ?? "") ?? "", isOnline),
      title: Text(userData["nickname"] ?? "알 수 없는 사용자", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("등급: $rank", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), // 등급 위치 조정
          Text("홈샵: ${userData["homeShop"] ?? "없음"}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text("${userData["dartBoard"] ?? "없음"} | 레이팅: $rating", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text("메시지 설정: $messageSetting", style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: user.id,
              nickname: userData["nickname"] ?? "알 수 없음",
              profileImage: _firestoreService.sanitizeProfileImage(userData["profileImage"] ?? "") ?? "",
              isCurrentUser: user.id == currentUserId,
            ),
          ),
        );
      },
    );
  }

  /// 필터 & 검색 UI
  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
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
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (value) => setState(() => homeShopSearch = value.trim()),
                    decoration: InputDecoration(
                      labelText: "홈샵 검색",
                      labelStyle: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                      prefixIcon: Icon(Icons.search, size: 18, color: Theme.of(context).iconTheme.color),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  /// 통계 아이템 UI
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }

  /// 프로필 통계 UI
  Widget _buildProfileStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: profileStatsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "통계 정보를 불러오는 중 오류가 발생했습니다.",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        var stats = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
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

  /// 프로필 이미지 (이미지 로드 오류 처리 강화)
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
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
      ],
    );
  }

  /// 드롭다운 필터 UI
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