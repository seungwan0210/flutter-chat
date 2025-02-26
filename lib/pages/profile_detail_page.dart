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
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
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
      _resetTodayViewsIfNeeded(widget.userId); // ✅ 오늘 날짜 확인 후 필요하면 `todayViews` 초기화
      _increaseProfileView(widget.userId); // ✅ 프로필 방문 시 조회수 증가
    }
  }

  /// ✅ **하루가 지나면 `todayViews`를 0으로 리셋**
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
          return; // ✅ 오늘 이미 초기화되었으면 종료
        }
      }

      // ✅ 오늘 날짜가 다르면 todayViews를 0으로 초기화
      await userRef.update({
        "todayViews": 0,
        "lastResetAt": FieldValue.serverTimestamp(),
      });

      print("🔥 새로운 하루 시작! todayViews = 0으로 초기화됨.");
    }
  }

  /// ✅ **프로필 조회 시 조회수 증가 (중복 조회 방지)**
  Future<void> _increaseProfileView(String viewedUserId) async {
    String currentUserId = _auth.currentUser!.uid;
    if (currentUserId == viewedUserId) {
      print("🚫 본인 프로필 조회 - 조회수 증가 방지");
      return;
    }

    DocumentReference profileRef = FirebaseFirestore.instance.collection("users").doc(viewedUserId);
    DocumentReference viewRef = profileRef.collection("profile_views").doc(currentUserId);

    // ✅ Firestore에서 방문 기록 가져오기
    DocumentSnapshot viewSnapshot = await viewRef.get();
    DateTime today = DateTime.now();
    String todayStr = "${today.year}-${today.month}-${today.day}";

    if (viewSnapshot.exists) {
      // ✅ 방문 기록이 있으면 마지막 방문 날짜 가져오기
      Timestamp lastViewedAt = viewSnapshot["viewedAt"];
      DateTime lastViewedDate = lastViewedAt.toDate();
      String lastViewedStr = "${lastViewedDate.year}-${lastViewedDate.month}-${lastViewedDate.day}";

      if (lastViewedStr == todayStr) {
        print("✅ 오늘 이미 방문한 사용자, 카운트 X");
        return; // ✅ 같은 날이면 카운트 증가 안함
      }
    }

    // ✅ 방문 기록 업데이트 (새로운 방문이거나, 새로운 날 방문한 경우)
    await viewRef.set({
      "viewedAt": FieldValue.serverTimestamp(), // ✅ Firestore에서 현재 시간 기록
    });

    // ✅ 총 검색량 +1 & 오늘 검색량 +1 증가
    await profileRef.update({
      "totalViews": FieldValue.increment(1),
      "todayViews": FieldValue.increment(1),
    });

    print("🔥 프로필 방문 수 증가 완료! totalViews +1, todayViews +1");
  }

  /// ✅ **유저 정보 불러오기**
  void _loadUserInfo() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserDataById(
        widget.userId);
    if (userData != null) {
      setState(() {
        _rating = userData["rating"] ?? 0;
        _dartBoard = userData["dartBoard"] ?? "정보 없음";
        _homeShop = userData["homeShop"] ?? "없음";
        totalViews = userData["totalViews"] ?? 0;
        dailyViews = userData["todayViews"] ?? 0;
        friendCount =
        userData.containsKey("friendCount") ? userData["friendCount"] : 0;
        messageSetting = userData["messageSetting"] ?? "전체 허용";
      });
    }
  }

  /// ✅ **차단 여부 확인**
  void _checkIfBlocked() async {
    _isBlocked = await _firestoreService.isUserBlocked(widget.userId);
    setState(() {});
  }

  void _toggleBlock() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserDataById(widget.userId);

    if (userData != null) {
      String nickname = userData["nickname"] ?? "알 수 없음";
      String profileImage = userData["profileImage"] ?? "";

      await _firestoreService.toggleBlockUser(widget.userId, nickname, profileImage);

      setState(() {
        _isBlocked = !_isBlocked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBlocked ? "사용자를 차단했습니다." : "차단을 해제했습니다.")),
      );
    }
  }


  /// ✅ **친구 요청 기능**
  void _sendFriendRequest() async {
    await _firestoreService.sendFriendRequest(widget.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("친구 요청을 보냈습니다.")),
    );
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
            const SizedBox(height: 30),
            widget.isCurrentUser ? _buildOwnProfileButtons() : _buildOtherUserButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnProfileButtons() {
    return Column(
      children: [
        _buildIconButton(Icons.chat, "나와의 채팅", () {}),
        const SizedBox(height: 10),
        _buildIconButton(Icons.settings, "프로필 설정", () {}),
      ],
    );
  }

  Widget _buildOtherUserButtons() {
    return Column(
      children: [
        _buildIconButton(Icons.chat, "1:1 채팅", () {}),
        const SizedBox(height: 10),
        _buildIconButton(Icons.person_add, "친구 추가", _sendFriendRequest),
        const SizedBox(height: 10),
        _buildIconButton(
          Icons.block,
          _isBlocked ? "차단 해제" : "차단",
          _toggleBlock,
          color: Colors.red,
        ),
      ],
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

  Widget _buildIconButton(IconData icon, String text, VoidCallback onPressed, {Color color = Colors.blue}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text),
      style: ElevatedButton.styleFrom(backgroundColor: color),
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
