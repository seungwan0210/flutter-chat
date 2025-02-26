import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _groupMembers = [];

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    Map<String, dynamic>? groupData = await _firestoreService.getGroupById(widget.groupId);
    List<Map<String, dynamic>> members = await _firestoreService.getGroupMembers(widget.groupId);

    setState(() {
      _groupData = groupData;
      _groupMembers = members;
    });
  }

  Future<void> _leaveGroup() async {
    await _firestoreService.leaveGroup(widget.groupId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("그룹을 탈퇴했습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupData?["groupName"] ?? "그룹 상세"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _leaveGroup,
          ),
        ],
      ),
      body: _groupData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_groupData?["groupImage"] ?? ""),
                  child: _groupData?["groupImage"] == null ? const Icon(Icons.group, size: 50) : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _groupData?["groupName"] ?? "그룹 이름 없음",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${_groupData?["memberCount"] ?? 0}명 참여 중",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "그룹 멤버",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _groupMembers.isEmpty
                ? const Center(child: Text("그룹 멤버가 없습니다."))
                : ListView.builder(
              itemCount: _groupMembers.length,
              itemBuilder: (context, index) {
                final member = _groupMembers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(member["profileImage"] ?? ""),
                    child: member["profileImage"] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(member["nickname"] ?? "알 수 없는 사용자"),
                  subtitle: Text("@${member["userId"]}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
