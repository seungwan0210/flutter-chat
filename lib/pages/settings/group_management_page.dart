import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/settings/group_detail_page.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({Key? key}) : super(key: key);

  @override
  _GroupManagementPageState createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    List<Map<String, dynamic>> groups = await _firestoreService.getUserGroups();
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _deleteGroup(String groupId) async {
    await _firestoreService.deleteGroup(groupId);
    _loadGroups(); // 그룹 삭제 후 목록 갱신
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("그룹이 삭제되었습니다.")),
    );
  }

  Future<void> _navigateToGroupPage(String groupId) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: groupId)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("그룹 관리"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupCreatePage()),
              // 그룹 생성 페이지로 이동
              // Navigator.push(context, MaterialPageRoute(builder: (context) => GroupCreatePage()));
            },
          ),
        ],
      ),
      body: _groups.isEmpty
          ? const Center(child: Text("참여 중인 그룹이 없습니다."))
          : ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(group["groupImage"] ?? ""),
              child: group["groupImage"] == null ? const Icon(Icons.group) : null,
            ),
            title: Text(group["groupName"] ?? "알 수 없는 그룹"),
            subtitle: Text("${group["memberCount"] ?? 0}명 참여 중"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteGroup(group["groupId"]),
            ),
            onTap: () => _navigateToGroupPage(group["groupId"]),
          );
        },
      ),
    );
  }
}
