import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class GroupInvitePage extends StatefulWidget {
  final String groupId;

  const GroupInvitePage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupInvitePageState createState() => _GroupInvitePageState();
}

class _GroupInvitePageState extends State<GroupInvitePage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _friends = [];
  List<String> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    List<Map<String, dynamic>> friends = await _firestoreService.getFriendsList();
    setState(() {
      _friends = friends;
    });
  }

  Future<void> _inviteUsers() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("초대할 사용자를 선택하세요.")),
      );
      return;
    }

    await _firestoreService.inviteUsersToGroup(widget.groupId, _selectedUsers);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("초대가 완료되었습니다.")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("그룹 초대"),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _inviteUsers,
          ),
        ],
      ),
      body: _friends.isEmpty
          ? const Center(child: Text("초대할 친구가 없습니다."))
          : ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          bool isSelected = _selectedUsers.contains(friend["userId"]);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(friend["profileImage"] ?? ""),
              child: friend["profileImage"] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(friend["nickname"] ?? "알 수 없는 사용자"),
            subtitle: Text("@${friend["userId"]}"),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedUsers.add(friend["userId"]);
                  } else {
                    _selectedUsers.remove(friend["userId"]);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
