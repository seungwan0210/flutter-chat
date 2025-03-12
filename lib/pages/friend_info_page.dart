import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import '../../services/firestore_service.dart';

class FriendInfoPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImage;

  const FriendInfoPage({super.key, required this.receiverId, required this.receiverImage, required this.receiverName});

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

  @override
  void initState() {
    super.initState();
    _loadFriendInfo();
    _checkFavoriteStatus();
  }

  Future<void> _loadFriendInfo() async {
    try {
      DocumentSnapshot friendSnapshot = await _firestore.collection("users").doc(widget.receiverId).get();

      if (friendSnapshot.exists) {
        setState(() {
          _friendData = friendSnapshot.data() as Map<String, dynamic>?;
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
    DocumentSnapshot favoriteDoc = await _firestore.collection("users").doc(currentUserId).collection("favorites").doc(widget.receiverId).get();
    setState(() {
      _isFavorite = favoriteDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    String currentUserId = _auth.currentUser!.uid;
    if (_isFavorite) {
      await _firestore.collection("users").doc(currentUserId).collection("favorites").doc(widget.receiverId).delete();
    } else {
      await _firestore.collection("users").doc(currentUserId).collection("favorites").doc(widget.receiverId).set({});
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
          chatPartnerImage: _firestoreService.sanitizeProfileImage(widget.receiverImage) ?? "",
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
        ),
      ),
    );
  }

  String _getChatRoomId(String userId, String receiverId) {
    return userId.hashCode <= receiverId.hashCode
        ? '$userId\_$receiverId'
        : '$receiverId\_$userId';
  }

  Future<void> _removeFriend() async {
    String currentUserId = _auth.currentUser!.uid;

    try {
      await _firestore.collection("users").doc(currentUserId).collection("friends").doc(widget.receiverId).delete();
      await _firestore.collection("users").doc(widget.receiverId).collection("friends").doc(currentUserId).delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구가 삭제되었습니다.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구 삭제에 실패했습니다.")));
    }
  }

  Future<void> _blockFriend() async {
    String currentUserId = _auth.currentUser!.uid;

    try {
      await _firestore.collection("users").doc(currentUserId).collection("blockedUsers").doc(widget.receiverId).set({
        "blockedAt": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구가 차단되었습니다.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("친구 차단에 실패했습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("친구 정보", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendData == null
          ? const Center(child: Text("친구 정보를 불러올 수 없습니다.", style: TextStyle(fontSize: 16)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: _firestoreService.sanitizeProfileImage(_friendData!["profileImage"] ?? "").isNotEmpty
                          ? NetworkImage(_firestoreService.sanitizeProfileImage(_friendData!["profileImage"] ?? ""))
                          : null,
                      foregroundImage: _firestoreService.sanitizeProfileImage(_friendData!["profileImage"] ?? "").isNotEmpty &&
                          !Uri.tryParse(_firestoreService.sanitizeProfileImage(_friendData!["profileImage"] ?? ""))!.hasAbsolutePath
                          ? const AssetImage("assets/default_profile.png") as ImageProvider
                          : null,
                      child: _firestoreService.sanitizeProfileImage(_friendData!["profileImage"] ?? "").isEmpty
                          ? const Icon(Icons.person, size: 70)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _friendData!["nickname"] ?? "알 수 없음",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _infoTile(Icons.store, "홈샵", _friendData!["homeShop"] ?? "없음"),
                    _infoTile(Icons.star, "레이팅", _friendData!.containsKey("rating") ? "${_friendData!["rating"]}" : "정보 없음"),
                    _infoTile(Icons.sports_esports, "다트 보드", _friendData!["dartBoard"] ?? "정보 없음"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildActionButton(Icons.chat, "메시지 보내기", Theme.of(context).primaryColor!, _startChat),
            _buildActionButton(Icons.star_border, "즐겨찾기", _isFavorite ? Colors.amber : Colors.grey, _toggleFavorite),
            _buildActionButton(Icons.person_remove, "친구 삭제", Theme.of(context).colorScheme.error!, _removeFriend),
            _buildActionButton(Icons.block, "차단하기", Theme.of(context).disabledColor!, _blockFriend),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}