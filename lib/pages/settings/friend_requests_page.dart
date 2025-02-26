import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({Key? key}) : super(key: key);

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _friendRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  /// ✅ Firestore에서 친구 요청 목록 실시간 감지
  void _loadFriendRequests() {
    _firestoreService.listenToFriendRequests().listen((requests) {
      setState(() {
        _friendRequests = requests;
      });
    });
  }

  /// ✅ 친구 요청 승인 (리스트에서 즉시 제거)
  Future<void> _acceptFriend(String? userId) async {
    if (userId == null || userId.isEmpty) {
      print("🚨 오류: userId가 null입니다.");
      return;
    }

    setState(() {
      _friendRequests.removeWhere((request) => request["userId"] == userId);
    });

    await _firestoreService.acceptFriendRequest(userId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("친구 요청을 승인했습니다.")),
    );
  }

  /// ✅ 친구 요청 거절 (리스트에서 즉시 제거)
  Future<void> _declineFriend(String? userId) async {
    if (userId == null || userId.isEmpty) {
      print("🚨 오류: userId가 null입니다.");
      return;
    }

    setState(() {
      _friendRequests.removeWhere((request) => request["userId"] == userId);
    });

    await _firestoreService.declineFriendRequest(userId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("친구 요청을 거절했습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("친구 요청")),
      body: _friendRequests.isEmpty
          ? const Center(child: Text("받은 친구 요청이 없습니다."))
          : ListView.builder(
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          final String userId = request["userId"] ?? ""; // ✅ null 방지
          final String nickname = request["nickname"] ?? "알 수 없는 사용자";
          final String profileImage = request["profileImage"] ?? "";

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileImage.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(nickname),
            subtitle: Text("@$userId"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _acceptFriend(userId),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _declineFriend(userId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
