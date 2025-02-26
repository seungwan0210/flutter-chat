import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("차단된 사용자 목록")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection("users").doc(currentUserId).collection("blockedUsers").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var blockedUsers = snapshot.data!.docs;
          if (blockedUsers.isEmpty) return const Center(child: Text("차단된 사용자가 없습니다."));

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              var blockedUser = blockedUsers[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: blockedUser["profileImage"] != ""
                      ? NetworkImage(blockedUser["profileImage"])
                      : null,
                  child: blockedUser["profileImage"] == "" ? const Icon(Icons.person) : null,
                ),
                title: Text(blockedUser["nickname"]),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _unblockUser(currentUserId, blockedUser.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _unblockUser(String currentUserId, String blockedUserId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection("users").doc(currentUserId).collection("blockedUsers").doc(blockedUserId).delete();
  }
}
