import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_page.dart';
import 'play_summary_page.dart';
import 'package:dartschat/pages/profile_page.dart';

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
    DocumentReference userRef = FirebaseFirestore.instance.collection("users")
        .doc(userId);
    DocumentSnapshot userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      Timestamp? lastResetAt = userSnapshot["lastResetAt"];
      DateTime today = DateTime.now();
      String todayStr = "${today.year}-${today.month}-${today.day}";

      if (lastResetAt != null) {
        DateTime lastResetDate = lastResetAt.toDate();
        String lastResetStr = "${lastResetDate.year}-${lastResetDate
            .month}-${lastResetDate.day}";

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


    DocumentReference profileRef = FirebaseFirestore.instance.collection(
        "users").doc(viewedUserId);
    DocumentReference viewRef = profileRef.collection("profile_views").doc(
        currentUserId);

    DocumentSnapshot viewSnapshot = await viewRef.get();
    DateTime today = DateTime.now();
    String todayStr = "${today.year}-${today.month}-${today.day}";

    if (viewSnapshot.exists) {
      Timestamp lastViewedAt = viewSnapshot["viewedAt"];
      DateTime lastViewedDate = lastViewedAt.toDate();
      String lastViewedStr = "${lastViewedDate.year}-${lastViewedDate
          .month}-${lastViewedDate.day}";

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
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
        "users").doc(widget.userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("프로필 상세", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF182848)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  /// ✅ 프로필 정보 카드 (버튼 추가)
  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(Icons.store, "홈샵", _homeShop),
              _buildInfoRow(
                  Icons.star, "레이팅", _rating > 0 ? "$_rating" : "미등록"),
              _buildInfoRow(Icons.sports_esports, "다트 보드", _dartBoard),
              const SizedBox(height: 20),
              _buildActionButtons(), // ✅ 여기에 버튼 추가!
            ],
          ),
        ),
      ),
    );
  }


  /// ✅ 같은 유저끼리는 항상 같은 채팅방 ID 생성
  String _getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); // 항상 같은 순서로 정렬
    return ids.join("_"); // "user1_user2" 형태로 ID 생성
  }

  /// ✅ 내 프로필 vs 상대방 프로필 버튼 다르게 표시
  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      // 🔥 내 프로필일 때
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            icon: const Icon(Icons.settings),
            label: const Text("프로필 설정"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const PlaySummaryPage()));
            },
            icon: const Icon(Icons.timeline),
            label: const Text("오늘의 플레이 요약"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    } else {
      // 🔥 상대방 프로필일 때
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              String senderId = _auth.currentUser!.uid;
              String receiverId = widget.userId;

              // ✅ Firestore에서 기존 채팅방 찾기
              QuerySnapshot chatRoomQuery = await FirebaseFirestore.instance
                  .collection("chats")
                  .where("participants", arrayContains: senderId)
                  .get();

              String chatRoomId;
              DocumentReference? existingChatRoom;

              // ✅ 기존 채팅방이 있는지 확인
              for (var doc in chatRoomQuery.docs) {
                List participants = doc["participants"];
                if (participants.contains(receiverId)) {
                  existingChatRoom = doc.reference;
                  break;
                }
              }

              if (existingChatRoom != null) {
                chatRoomId = existingChatRoom.id; // ✅ 기존 채팅방 사용
              } else {
                // ✅ 기존 채팅방이 없으면 새로 생성
                chatRoomId = _getChatRoomId(senderId, receiverId);
                await FirebaseFirestore.instance.collection("chats").doc(
                    chatRoomId).set({
                  "participants": [senderId, receiverId],
                  "lastMessage": "",
                  "timestamp": Timestamp.now(),
                });
              }

              // ✅ ChatPage로 이동 (기존 채팅방 ID 유지)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatRoomId: chatRoomId, // ✅ chatRoomId 추가
                    chatPartnerName: widget.nickname, // ✅ receiverName → chatPartnerName 변경
                    chatPartnerImage: widget.profileImage ?? "", // ✅ 상대방 프로필 이미지 추가
                    receiverId: receiverId,
                    receiverName: widget.nickname,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text("메시지 보내기"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _sendFriendRequest, // ✅ 친구 요청 기능 추가
            icon: const Icon(Icons.person_add),
            label: const Text("친구 추가"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    }
  }

  /// ✅ 친구 요청 보내기 기능
  Future<void> _sendFriendRequest() async {
    await _firestoreService.sendFriendRequest(widget.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("친구 요청을 보냈습니다.")),
    );
  }


  /// ✅ 아이콘 + 정보 표시
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  /// ✅ 프로필 헤더 (이미지 + 닉네임)
  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(widget.profileImage),
          // ✅ 이미지 확대 보기 추가
          child: CircleAvatar(
            radius: 70,
            backgroundImage: widget.profileImage.isNotEmpty
                ? NetworkImage(widget.profileImage)
                : const AssetImage(
                "assets/default_profile.png") as ImageProvider,
            child: widget.profileImage.isEmpty
                ? const Icon(Icons.person, size: 70, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.nickname,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  /// ✅ **풀스크린 이미지 확대 다이얼로그**
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : Image.asset(
                    "assets/default_profile.png", fit: BoxFit.contain),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
