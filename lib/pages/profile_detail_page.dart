import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_page.dart';
import 'play_summary_page.dart';
import 'profile_page.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final List<Map<String, dynamic>> profileImages;
  final bool isCurrentUser;

  const ProfileDetailPage({
    super.key,
    required this.userId,
    required this.nickname,
    required this.profileImages,
    required this.isCurrentUser,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isBlocked = false;
  bool _isFriend = false;
  bool _isRequestPending = false;
  int _rating = 0;
  String _dartBoard = "정보 없음";
  String _homeShop = "없음";
  int totalViews = 0;
  int dailyViews = 0;
  String messageSetting = "전체 허용";
  String? _errorMessage;
  String _rank = "💀"; // 초기값을 해골로 설정
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isDiamond = false; // 다이아 등급 여부
  bool _isActive = true; // 계정 활성화 상태

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
    _loadUserInfo();

    if (!widget.isCurrentUser) {
      _increaseProfileView(widget.userId);
    }
  }

  /// 날짜 문자열 생성
  String _getDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  /// 등급 계산 (11단계, 이모티콘으로 반환)
  String _calculateRank(int totalViews, bool isDiamond) {
    if (isDiamond) return "💎"; // 다이아 (어드민 지정)
    if (totalViews >= 20000) return "✨"; // 금별
    if (totalViews >= 10000) return "⭐"; // 은별
    if (totalViews >= 5000) return "🌟"; // 동별
    if (totalViews >= 3000) return "🏆"; // 금훈장
    if (totalViews >= 2500) return "🏅"; // 은훈장
    if (totalViews >= 2200) return "🎖️"; // 동훈장
    if (totalViews >= 1500) return "🥇"; // 금메달
    if (totalViews >= 500) return "🥈"; // 은메달
    if (totalViews >= 300) return "🥉"; // 동메달
    return "💀"; // 해골
  }

  /// 친구 상태 및 요청 상태 확인
  Future<void> _checkFriendStatus() async {
    String currentUserId = _auth.currentUser!.uid;

    DocumentSnapshot friendDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("friends")
        .doc(widget.userId)
        .get();
    if (mounted) {
      setState(() {
        _isFriend = friendDoc.exists;
      });
    }

    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("friendRequests")
        .doc(currentUserId)
        .get();
    if (mounted) {
      setState(() {
        _isRequestPending = requestDoc.exists;
      });
    }
  }

  /// 프로필 조회 시 조회수 증가 (중복 조회 방지)
  Future<void> _increaseProfileView(String viewedUserId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      if (currentUserId == viewedUserId) return;

      DocumentReference profileRef = FirebaseFirestore.instance.collection("users").doc(viewedUserId);
      DocumentSnapshot profileSnapshot = await profileRef.get();
      if (!profileSnapshot.exists || !(profileSnapshot["isActive"] ?? true)) return; // 비활성화된 유저는 조회수 증가 제외

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
      batch.set(viewRef, {
        "viewedAt": FieldValue.serverTimestamp(),
        "viewerId": currentUserId,
      });
      batch.update(profileRef, {
        "totalViews": FieldValue.increment(1),
        "todayViews": FieldValue.increment(1),
      });

      await batch.commit();

      DocumentSnapshot updatedProfile = await profileRef.get();
      if (updatedProfile.exists) {
        Map<String, dynamic>? updatedData = updatedProfile.data() as Map<String, dynamic>?;
        if (updatedData != null) {
          if (mounted) {
            setState(() {
              totalViews = updatedData["totalViews"] ?? 0;
              dailyViews = updatedData["todayViews"] ?? 0;
              _isDiamond = updatedData["isDiamond"] ?? false;
              _rank = _calculateRank(totalViews, _isDiamond);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "프로필 조회수 증가 중 오류: $e";
        });
      }
    }
  }

  /// 유저 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(widget.userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          if (mounted) {
            setState(() {
              _rating = userData["rating"] ?? 0;
              _dartBoard = userData["dartBoard"] ?? "정보 없음";
              _homeShop = userData["homeShop"] ?? "없음";
              totalViews = userData["totalViews"] ?? 0;
              dailyViews = userData["todayViews"] ?? 0;
              messageSetting = userData["messageReceiveSetting"] ?? "전체 허용";
              _isDiamond = userData["isDiamond"] ?? false;
              _rank = _calculateRank(totalViews, _isDiamond);
              _profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
              _mainProfileImage = userData["mainProfileImage"];
              _isActive = userData["isActive"] ?? true; // 계정 활성화 상태 설정
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = "유저 데이터가 비어 있습니다.";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "유저 정보를 찾을 수 없습니다.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "유저 정보를 불러오는 중 오류: $e";
        });
      }
    }
  }

  /// 차단/차단 해제 토글
  Future<void> _toggleBlockUser() async {
    try {
      await _firestoreService.toggleBlockUser(widget.userId, widget.nickname, widget.profileImages);

      // 차단 상태가 토글된 후 Firestore에서 최신 상태를 가져와 UI 업데이트
      DocumentReference userRef = FirebaseFirestore.instance.collection("users").doc(widget.userId);
      DocumentSnapshot userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        int newBlockedByCount = userSnapshot["blockedByCount"] ?? 0;
        bool newIsActive = userSnapshot["isActive"] ?? true;
        setState(() {
          _isBlocked = !_isBlocked; // 차단 상태 토글
          _isActive = newIsActive; // 계정 활성화 상태 업데이트
        });

        if (newBlockedByCount >= 10 && newIsActive) {
          // Cloud Function에서 처리되므로 추가 확인 불필요
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBlocked ? "차단이 해제되었습니다." : "사용자가 차단되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("차단/차단 해제 중 오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "프로필 상세",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildProfileStats(),
            const SizedBox(height: 16),
            _buildProfileInfo(),
            const SizedBox(height: 16),
            if (!_isActive)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "이 계정은 비활성화되었습니다.",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            if (_isActive) _buildActionButtons(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 프로필 헤더
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 80, bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              List<String> validImageUrls = _profileImages
                  .map((img) => img['url'] as String?)
                  .where((url) => url != null && url.isNotEmpty)
                  .cast<String>()
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    imageUrls: validImageUrls,
                    initialIndex: _mainProfileImage != null && validImageUrls.contains(_mainProfileImage)
                        ? validImageUrls.indexOf(_mainProfileImage!)
                        : 0,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black,
                backgroundImage: _mainProfileImage != null && _mainProfileImage!.isNotEmpty ? NetworkImage(_mainProfileImage!) : null,
                child: _mainProfileImage == null || _mainProfileImage!.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.nickname,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 정보
  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Total", "$totalViews"),
          _buildStatItem("Today", "$dailyViews"),
          _buildStatItem("Rank", _rank),
        ],
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 프로필 정보
  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.store, "홈샵", _homeShop),
          _buildInfoRow(Icons.star, "레이팅", _rating > 0 ? "$_rating" : "미등록"),
          _buildInfoRow(Icons.sports_esports, "다트 보드", _dartBoard),
          _buildInfoRow(Icons.message, "메시지 설정", messageSetting),
        ],
      ),
    );
  }

  /// 정보 아이템
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼
  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.settings,
              label: "프로필 설정",
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.timeline,
              label: "오늘의 플레이 요약",
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaySummaryPage()));
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.message,
              label: "메시지 보내기",
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: _isActive
                  ? () async {
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
                      chatPartnerImage: _mainProfileImage ?? "",
                      receiverId: receiverId,
                      receiverName: widget.nickname,
                    ),
                  ),
                );
              }
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("비활성화된 계정과는 메시지를 보낼 수 없습니다.")),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<bool>(
              stream: _firestoreService.listenToBlockedStatus(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text(
                    "차단 상태 로드 중 오류",
                    style: TextStyle(color: Colors.redAccent),
                  );
                }

                _isBlocked = snapshot.data ?? false;
                return Column(
                  children: [
                    _buildFriendActionButton(),
                    const SizedBox(height: 12),
                    _buildBlockActionButton(),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }
  }

  /// 친구 관련 액션 버튼
  Widget _buildFriendActionButton() {
    if (_isBlocked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "차단된 사용자입니다.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (_isFriend) {
      return _buildActionButton(
        icon: Icons.person_remove,
        label: "친구 삭제",
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.red],
        ),
        onPressed: _removeFriend,
      );
    } else if (_isRequestPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "요청됨",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return _buildActionButton(
        icon: Icons.person_add,
        label: "친구 추가",
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        onPressed: _isActive
            ? _sendFriendRequest
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("비활성화된 계정은 친구로 추가할 수 없습니다.")),
          );
        },
      );
    }
  }

  /// 차단/차단 해제 버튼
  Widget _buildBlockActionButton() {
    return _buildActionButton(
      icon: _isBlocked ? Icons.block : Icons.block_outlined,
      label: _isBlocked ? "차단 해제" : "차단",
      gradient: _isBlocked
          ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
          : const LinearGradient(colors: [Colors.redAccent, Colors.red]),
      onPressed: _toggleBlockUser,
    );
  }

  /// 액션 버튼 스타일링
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// 친구 요청 보내기 기능
  Future<void> _sendFriendRequest() async {
    try {
      await _firestoreService.sendFriendRequest(widget.userId);
      if (mounted) {
        setState(() {
          _isRequestPending = true;
        });
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

  /// 친구 삭제 기능
  Future<void> _removeFriend() async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      await _firestoreService.removeFriend(widget.userId);
      if (mounted) {
        setState(() {
          _isFriend = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구가 삭제되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 삭제 중 오류가 발생했습니다: $e")),
        );
      }
    }
  }
}