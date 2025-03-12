import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  _BlockedUsersPageState createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final FirestoreService _firestoreService = FirestoreService();

  /// 차단 해제 기능
  Future<void> _unblockUser(String userId) async {
    try {
      await _firestoreService.unblockUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("차단이 해제되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("차단 해제 중 오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "차단 관리",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.listenToBlockedUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "차단 목록을 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          List<Map<String, dynamic>> blockedUsers = snapshot.data!;

          if (blockedUsers.isEmpty) {
            return Center(
              child: Text(
                "차단된 사용자가 없습니다.",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              String sanitizedProfileImage = _firestoreService.sanitizeProfileImage(user["profileImage"] ?? "");
              String nickname = user["nickname"] ?? "알 수 없는 사용자";
              String userId = user["userId"] ?? "ID 없음";

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: sanitizedProfileImage.isNotEmpty ? NetworkImage(sanitizedProfileImage) : null,
                    foregroundImage: sanitizedProfileImage.isNotEmpty && !Uri.tryParse(sanitizedProfileImage)!.hasAbsolutePath
                        ? const AssetImage("assets/default_profile.png") as ImageProvider
                        : null,
                    child: sanitizedProfileImage.isEmpty
                        ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color)
                        : null,
                  ),
                  title: Text(
                    nickname,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "@$userId",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _unblockUser(user["userId"]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}