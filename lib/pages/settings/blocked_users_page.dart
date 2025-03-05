import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  _BlockedUsersPageState createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final FirestoreService _firestoreService = FirestoreService();

  /// ✅ 차단 해제 기능
  Future<void> _unblockUser(String userId) async {
    await _firestoreService.unblockUser(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("차단이 해제되었습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("차단 관리")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.listenToBlockedUsers(), // ✅ 실시간 반영
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("차단된 사용자가 없습니다."));
          }

          List<Map<String, dynamic>> blockedUsers = snapshot.data!;

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (user["profileImage"] ?? "").isNotEmpty
                      ? NetworkImage(user["profileImage"])
                      : null,
                  child: (user["profileImage"] ?? "").isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user["nickname"] ?? "알 수 없는 사용자"),
                subtitle: Text("@${user["userId"]}"),
                trailing: IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => _unblockUser(user["userId"]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
