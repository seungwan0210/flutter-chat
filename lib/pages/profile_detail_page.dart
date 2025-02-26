import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_page.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String profileImage;
  final bool isCurrentUser;

  const ProfileDetailPage({
    super.key,
    required this.userId,
    required this.nickname,
    required this.profileImage,
    required this.isCurrentUser,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isBlocked = false;
  int _rating = 0;
  String _dartBoard = "정보 없음";
  String _homeShop = "없음";
  int totalViews = 0;
  int dailyViews = 0;
  int friendCount = 0;
  String messageSetting = "전체 허용";

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
    _loadUserInfo();

    if (!widget.isCurrentUser) {
      _resetTodayViewsIfNeeded(widget.userId);
      _increaseProfileView(widget.userId);
    }
  }

  /// ✅ 차단 여부 확인
  void _checkIfBlocked() async {
    _isBlocked = await _firestoreService.isUserBlocked(widget.userId);
    setState(() {});
  }

  /// ✅ 하루가 지나면 `todayViews`를 0으로 리셋
  Future<void> _resetTodayViewsIfNeeded(String userId) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection("users").doc(userId);
    DocumentSnapshot userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      Timestamp? lastResetAt = userSnapshot["lastResetAt"];
      DateTime today = DateTime.now();
      String todayStr = "${today.year}-${today.month}-${today.day}";

      if (lastResetAt != null) {
        DateTime lastResetDate = lastResetAt.toDate();
        String lastResetStr = "${lastResetDate.year}-${lastResetDate.month}-${lastResetDate.day}";

        if (lastResetStr == todayStr) {
          print("✅ 오늘 이미 초기화됨");
          return;
        }
      }

      await userRef.update({
        "todayViews": 0,
        "lastResetAt": FieldValue.serverTimestamp(),
      });

      print("🔥 새로운 하루 시작! todayViews = 0으로 초기화됨.");
    }
  }
  /// ✅ 프로필 조회 시 조회수 증가 (중복 조회 방지)
  Future<void> _increaseProfileView(String viewedUserId) async {
    String currentUserId = _auth.currentUser!.uid;
    if (currentUserId == viewedUserId) {
      print("🚫 본인 프로필 조회 - 조회수 증가 방지");
      return;
    }

    DocumentReference profileRef = FirebaseFirestore.instance.collection("users").doc(viewedUserId);
    DocumentReference viewRef = profileRef.collection("profile_views").doc(currentUserId);

    DocumentSnapshot viewSnapshot = await viewRef.get();
    DateTime today = DateTime.now();
    String todayStr = "${today.year}-${today.month}-${today.day}";

    if (viewSnapshot.exists) {
      Timestamp lastViewedAt = viewSnapshot["viewedAt"];
      DateTime lastViewedDate = lastViewedAt.toDate();
      String lastViewedStr = "${lastViewedDate.year}-${lastViewedDate.month}-${lastViewedDate.day}";

      if (lastViewedStr == todayStr) {
        print("✅ 오늘 이미 방문한 사용자, 카운트 X");
        return;
      }
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();
    batch.set(viewRef, {"viewedAt": FieldValue.serverTimestamp()});
    batch.update(profileRef, {
      "totalViews": FieldValue.increment(1),
      "todayViews": FieldValue.increment(1),
    });

    await batch.commit();
    print("🔥 프로필 방문 수 증가 완료! totalViews +1, todayViews +1");
  }

  /// ✅ 유저 정보 불러오기
  void _loadUserInfo() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserDataById(widget.userId);
    if (userData != null) {
      setState(() {
        _rating = userData["rating"] ?? 0;
        _dartBoard = userData["dartBoard"] ?? "정보 없음";
        _homeShop = userData["homeShop"] ?? "없음";
        totalViews = userData["totalViews"] ?? 0;
        dailyViews = userData["todayViews"] ?? 0;
        friendCount = userData["friendCount"] ?? 0;
        messageSetting = userData["messageSetting"] ?? "전체 허용";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("프로필 상세")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: widget.profileImage.isNotEmpty
              ? NetworkImage(widget.profileImage)
              : const AssetImage("assets/default_profile.png") as ImageProvider,
          child: widget.profileImage.isEmpty ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
        ),
        const SizedBox(height: 15),
        Text(
          widget.nickname,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.store, "홈샵", _homeShop),
            _buildInfoRow(Icons.star, "레이팅", _rating > 0 ? "$_rating" : "미등록"),
            _buildInfoRow(Icons.sports_esports, "다트 보드", _dartBoard),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
