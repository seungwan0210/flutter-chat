import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/group_chat_service.dart';
import 'group_chat_page.dart';

class GroupChatListPage extends StatelessWidget {
  const GroupChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GroupChatService _groupChatService = GroupChatService();

    return Scaffold(
      appBar: AppBar(title: const Text("그룹 채팅")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupChatService.getUserGroups(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var groups = snapshot.data!.docs;
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              var group = groups[index];
              return ListTile(
                title: Text(group["name"]),
                subtitle: Text("${group["members"].length}명 참여 중"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatPage(groupId: group.id, groupName: group["name"]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
