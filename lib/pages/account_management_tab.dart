import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountManagementTab extends StatelessWidget {
  const AccountManagementTab({super.key});

  Future<void> _toggleUserActiveStatus(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "isActive": !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return const Center(child: Text("유저 목록 로드 중 오류", style: TextStyle(color: Colors.redAccent)));
        }

        var users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            String userId = user.id;
            Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
            String nickname = userData["nickname"] ?? "알 수 없음";
            bool isActive = userData["isActive"] ?? true;
            int blockedByCount = userData["blockedByCount"] ?? 0;

            return ListTile(
              title: Text(nickname, style: const TextStyle(color: Colors.black87)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("계정 상태: ${isActive ? "활성화" : "비활성화"}", style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                  Text("차단된 횟수: $blockedByCount", style: const TextStyle(color: Colors.black54)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(isActive ? Icons.lock_open : Icons.lock, color: isActive ? Colors.green : Colors.red),
                onPressed: () => _toggleUserActiveStatus(userId, isActive),
              ),
            );
          },
        );
      },
    );
  }
}