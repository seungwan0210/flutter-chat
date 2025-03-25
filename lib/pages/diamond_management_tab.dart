import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiamondManagementTab extends StatelessWidget {
  const DiamondManagementTab({super.key});

  Future<void> _toggleDiamondStatus(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "isDiamond": !currentStatus,
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
            bool isDiamond = userData["isDiamond"] ?? false;

            return ListTile(
              title: Text(nickname, style: const TextStyle(color: Colors.black87)),
              subtitle: Text("다이아 등급: ${isDiamond ? "예" : "아니오"}", style: const TextStyle(color: Colors.black54)),
              trailing: Switch(
                value: isDiamond,
                onChanged: (value) => _toggleDiamondStatus(userId, isDiamond),
                activeColor: Colors.amber,
              ),
            );
          },
        );
      },
    );
  }
}