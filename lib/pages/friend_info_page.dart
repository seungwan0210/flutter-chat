import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/pages/settings/blocked_users_page.dart';

class FriendInfoPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final List<Map<String, dynamic>> receiverImages;

  const FriendInfoPage({
    super.key,
    required this.receiverId,
    required this.receiverImages,
    required this.receiverName,
  });

  @override
  _FriendInfoPageState createState() => _FriendInfoPageState();
}

class _FriendInfoPageState extends State<FriendInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  Map<String, dynamic>? _friendData;
  bool _isFavorite = false;
  int totalViews = 0;
  int dailyViews = 0;
  String _rank = "브론즈";
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadFriendInfo();
    _checkFavoriteStatus();
    // 차단 상태 확인
    _firestoreService.listenToBlockedStatus(widget.receiverId).listen((isBlocked) {
      setState(() {
        _isBlocked = isBlocked;
      });
    });
  }

  Future<void> _loadFriendInfo() async {
    try {
      DocumentSnapshot friendSnapshot = await _firestore.collection("users").doc(widget.receiverId).get();

      if (friendSnapshot.exists) {
        setState(() {
          _friendData = friendSnapshot.data() as Map<String, dynamic>?;
          totalViews = _friendData!["totalViews"] ?? 0;
          dailyViews = _friendData!["todayViews"] ?? 0;
          _rank = _calculateRank(totalViews);
          _profileImages = _firestoreService.sanitizeProfileImages(_friendData!["profileImages"] ?? []);
          _mainProfileImage = _friendData!["mainProfileImage"];
          _isLoading = false;
        });
      } else {
        setState(() {
          _friendData = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 정보를 불러올 수 없습니다.")),
        );
      }
    } catch (e) {
      setState(() {
        _friendData = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구 정보 불러오기 실패: $e")),
      );
    }
  }

  Future<void> _checkFavoriteStatus() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot favoriteDoc = await _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("favorites")
        .doc(widget.receiverId)
        .get();
    setState(() {
      _isFavorite = favoriteDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    String currentUserId = _auth.currentUser!.uid;
    if (_isFavorite) {
      await _firestore
          .collection("users")
          .doc(currentUserId)
          .collection("favorites")
          .doc(widget.receiverId)
          .delete();
    } else {
      await _firestore
          .collection("users")
          .doc(currentUserId)
          .collection("favorites")
          .doc(widget.receiverId)
          .set({});
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _startChat() {
    String chatRoomId = _getChatRoomId(_auth.currentUser!.uid, widget.receiverId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          chatPartnerName: widget.receiverName,
          chatPartnerImage: _mainProfileImage ?? "",
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
        ),
      ),
    );
  }

  String _getChatRoomId(String userId, String receiverId) {
    return userId.hashCode <= receiverId.hashCode ? '$userId\_$receiverId' : '$receiverId\_$userId';
  }

  Future<void> _removeFriend() async {
    String currentUserId = _auth.currentUser!.uid;

    // 확인 다이얼로그 표시
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("친구 삭제"),
        content: const Text("친구를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.removeFriend(widget.receiverId);
        await _firestore
            .collection("users")
            .doc(currentUserId)
            .collection("favorites")
            .doc(widget.receiverId)
            .delete();

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구가 삭제되었습니다.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구 삭제에 실패했습니다.")));
      }
    }
  }

  Future<void> _blockFriend() async {
    String currentUserId = _auth.currentUser!.uid;

    // 확인 다이얼로그 표시
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("사용자 차단"),
        content: const Text("사용자를 차단하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("차단", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.toggleBlockUser(widget.receiverId, widget.receiverName, _profileImages);
        await _firestoreService.removeFriend(widget.receiverId);
        await _firestore
            .collection("users")
            .doc(currentUserId)
            .collection("favorites")
            .doc(widget.receiverId)
            .delete();

        // 차단 후 BlockedUsersPage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlockedUsersPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사용자가 차단되었습니다.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구 차단에 실패했습니다.")));
      }
    }
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "친구 정보",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isBlocked ? Icons.block : Icons.block_outlined,
              color: _isBlocked ? Colors.red : Colors.white,
            ),
            onPressed: _blockFriend,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendData == null
          ? const Center(child: Text("친구 정보를 불러올 수 없습니다.", style: TextStyle(fontSize: 16, color: Colors.white)))
          : SingleChildScrollView(
        child: Column(
          children: [
            // 상단 프로필 헤더
            _buildProfileHeader(),
            const SizedBox(height: 16),
            // 통계 정보
            _buildProfileStats(),
            const SizedBox(height: 16),
            // 프로필 정보
            _buildProfileInfo(),
            const SizedBox(height: 16),
            // 액션 버튼
            _buildActionButtons(),
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
            _friendData!["nickname"] ?? "알 수 없음",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "등급: $_rank",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
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
            color: Colors.black.withOpacity(0.2),
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
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(Icons.store, "홈샵", _friendData!["homeShop"] ?? "없음"),
          _infoTile(Icons.star, "레이팅", _friendData!.containsKey("rating") ? "${_friendData!["rating"]}" : "정보 없음"),
          _infoTile(Icons.sports_esports, "다트 보드", _friendData!["dartBoard"] ?? "정보 없음"),
        ],
      ),
    );
  }

  /// 정보 아이템
  Widget _infoTile(IconData icon, String title, String value) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(Icons.chat, "메시지 보내기", const LinearGradient(colors: [Colors.amber, Colors.orange]), _startChat),
          const SizedBox(height: 12),
          _buildActionButton(
            _isFavorite ? Icons.star : Icons.star_border,
            "즐겨찾기",
            _isFavorite
                ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                : const LinearGradient(colors: [Colors.grey, Colors.grey]),
            _toggleFavorite,
          ),
          const SizedBox(height: 12),
          _buildActionButton(Icons.person_remove, "친구 삭제", const LinearGradient(colors: [Colors.redAccent, Colors.red]), _removeFriend),
          const SizedBox(height: 12),
          _buildActionButton(Icons.block, "차단하기", const LinearGradient(colors: [Colors.grey, Colors.grey]), _blockFriend),
        ],
      ),
    );
  }

  /// 액션 버튼 스타일링
  Widget _buildActionButton(IconData icon, String label, LinearGradient gradient, VoidCallback onPressed) {
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
}