import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({super.key});

  @override
  _FriendManagementPageState createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();

  /// ✅ Firestore에서 친구 목록을 실시간 가져오기
  Stream<List<Map<String, dynamic>>> listenToFriends() {
    return _firestoreService.listenToFriends();
  }

  /// ✅ 친구 삭제 기능
  Future<void> removeFriend(String userId) async {
    await _firestoreService.removeFriend(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("친구가 삭제되었습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("친구 관리")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: listenToFriends(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("친구 목록이 없습니다."));
          }

          List<Map<String, dynamic>> friends = snapshot.data!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (friend["profileImage"] ?? "").isNotEmpty
                      ? NetworkImage(friend["profileImage"])
                      : null,
                  child: (friend["profileImage"] ?? "").isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(friend["nickname"] ?? "알 수 없는 사용자"),
                subtitle: Text("@${friend["userId"]}"),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => removeFriend(friend["userId"]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
