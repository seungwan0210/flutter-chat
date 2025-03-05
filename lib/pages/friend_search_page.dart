import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_page.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  _FriendSearchPageState createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  /// ✅ 검색 실행
  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("nickname", isGreaterThanOrEqualTo: query)
        .get();

    setState(() {
      _searchResults = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("친구 검색")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "닉네임 검색",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text("검색 결과가 없습니다."))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user["profileImage"] != null && user["profileImage"].isNotEmpty
                        ? NetworkImage(user["profileImage"])
                        : null,
                    child: user["profileImage"] == null || user["profileImage"].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user["nickname"] ?? "알 수 없음"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: user["userId"],
                          nickname: user["nickname"],
                          profileImage: user["profileImage"] ?? "",
                          isCurrentUser: false,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
