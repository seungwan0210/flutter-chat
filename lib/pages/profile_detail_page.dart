import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_page.dart';
import 'play_summary_page.dart';
import 'profile_page.dart';

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
  String? _errorMessage;

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

  /// 날짜 문자열 생성 (중복 제거)
  String _getDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  /// 차단 여부 확인
  Future<void> _checkIfBlocked() async {
    try {
      _isBlocked = await _firestoreService.isUserBlocked(widget.userId);
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = "차단 여부 확인 중 오류: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  /// 하루가 지나면 `todayViews`를 0으로 리셋
  Future<void> _resetTodayViewsIfNeeded(String userId) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection("users").doc(userId);
      DocumentSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        Timestamp? lastResetAt = userSnapshot["lastResetAt"];
        DateTime today = DateTime.now();
        String todayStr = _getDateString(today);

        if (lastResetAt != null) {
          DateTime lastResetDate = lastResetAt.toDate();
          String lastResetStr = _getDateString(lastResetDate);

          if (lastResetStr == todayStr) {
            return;
          }
        }

        await userRef.update({
          "todayViews": 0,
          "lastResetAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "todayViews 리셋 중 오류: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  /// 프로필 조회 시 조회수 증가 (중복 조회 방지)
  Future<void> _increaseProfileView(String viewedUserId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      if (currentUserId == viewedUserId) return;

      DocumentReference profileRef = FirebaseFirestore.instance.collection("users").doc(viewedUserId);
      DocumentReference viewRef = profileRef.collection("profile_views").doc(currentUserId);

      DocumentSnapshot viewSnapshot = await viewRef.get();
      DateTime today = DateTime.now();
      String todayStr = _getDateString(today);

      if (viewSnapshot.exists) {
        Timestamp lastViewedAt = viewSnapshot["viewedAt"];
        DateTime lastViewedDate = lastViewedAt.toDate();
        String lastViewedStr = _getDateString(lastViewedDate);

        if (lastViewedStr == todayStr) return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(viewRef, {"viewedAt": FieldValue.serverTimestamp()});
      batch.update(profileRef, {
        "totalViews": FieldValue.increment(1),
        "todayViews": FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      setState(() {
        _errorMessage = "프로필 조회수 증가 중 오류: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  /// 유저 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(widget.userId).get();
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
    } catch (e) {
      setState(() {
        _errorMessage = "유저 정보를 불러오는 중 오류: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String sanitizedProfileImage = _firestoreService.sanitizeProfileImage(widget.profileImage) ?? "";
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "프로필 상세",
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 배너
            Container(
              height: 100,
              color: Theme.of(context).cardColor,
              child: Center(
                child: Text(
                  "프로필 방문자 수: $totalViews (오늘: $dailyViews)",
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileHeader(sanitizedProfileImage),
            const SizedBox(height: 20),
            _buildProfileInfo(),
            if (_errorMessage != null) Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 헤더 (카카오톡 스타일로 조정)
  Widget _buildProfileHeader(String sanitizedProfileImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(sanitizedProfileImage),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Theme.of(context).cardColor,
              backgroundImage: sanitizedProfileImage.isNotEmpty ? NetworkImage(sanitizedProfileImage) : null,
              foregroundImage: sanitizedProfileImage.isNotEmpty && !Uri.tryParse(sanitizedProfileImage)!.hasAbsolutePath
                  ? const AssetImage("assets/default_profile.png") as ImageProvider
                  : null,
              child: sanitizedProfileImage.isEmpty
                  ? Icon(Icons.person, size: 70, color: Theme.of(context).textTheme.bodyLarge?.color)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.nickname,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "친구 수: $friendCount",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 정보 카드
  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 5,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(Icons.store, "홈샵", _homeShop),
              _buildInfoRow(Icons.star, "레이팅", _rating > 0 ? "$_rating" : "미등록"),
              _buildInfoRow(Icons.sports_esports, "다트 보드", _dartBoard),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 같은 유저끼리는 항상 같은 채팅방 ID 생성
  String _getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  /// 내 프로필 vs 상대방 프로필 버튼 다르게 표시
  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onPrimary),
            label: Text("프로필 설정", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaySummaryPage()));
            },
            icon: Icon(Icons.timeline, color: Theme.of(context).colorScheme.onSecondary),
            label: Text("오늘의 플레이 요약", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              String senderId = _auth.currentUser!.uid;
              String receiverId = widget.userId;

              QuerySnapshot chatRoomQuery = await FirebaseFirestore.instance
                  .collection("chats")
                  .where("participants", arrayContains: senderId)
                  .get();

              String chatRoomId;
              DocumentReference? existingChatRoom;

              for (var doc in chatRoomQuery.docs) {
                List participants = doc["participants"];
                if (participants.contains(receiverId)) {
                  existingChatRoom = doc.reference;
                  break;
                }
              }

              if (existingChatRoom != null) {
                chatRoomId = existingChatRoom.id;
              } else {
                chatRoomId = _getChatRoomId(senderId, receiverId);
                await FirebaseFirestore.instance.collection("chats").doc(chatRoomId).set({
                  "participants": [senderId, receiverId],
                  "lastMessage": "",
                  "timestamp": Timestamp.now(),
                });
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatRoomId: chatRoomId,
                    chatPartnerName: widget.nickname,
                    chatPartnerImage: _firestoreService.sanitizeProfileImage(widget.profileImage) ?? "",
                    receiverId: receiverId,
                    receiverName: widget.nickname,
                  ),
                ),
              );
            },
            icon: Icon(Icons.message, color: Theme.of(context).colorScheme.onPrimary),
            label: Text("메시지 보내기", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _sendFriendRequest,
            icon: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSecondary),
            label: Text("친구 추가", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    }
  }

  /// 친구 요청 보내기 기능
  Future<void> _sendFriendRequest() async {
    try {
      await _firestoreService.sendFriendRequest(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 요청을 보냈습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 중 오류가 발생했습니다: $e")),
        );
      }
    }
  }

  /// 아이콘 + 정보 표시
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }

  /// 풀스크린 이미지 확대 다이얼로그
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
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    "assets/default_profile.png",
                    fit: BoxFit.contain,
                  ),
                )
                    : Image.asset(
                  "assets/default_profile.png",
                  fit: BoxFit.contain,
                ),
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