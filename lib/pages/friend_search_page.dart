import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_page.dart';
import '../../services/firestore_service.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  _FriendSearchPageState createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final FirestoreService _firestoreService = FirestoreService();

  /// 검색 실행
  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("nickname", isGreaterThanOrEqualTo: query)
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['userId'] = doc.id; // 문서 ID를 userId로 추가
          return data;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("검색 중 오류가 발생했습니다: $e")),
      );
      setState(() => _searchResults = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("친구 검색"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "닉네임 검색",
                prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _searchUsers,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text("검색 결과가 없습니다."))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var user = _searchResults[index];
                String sanitizedProfileImage = _firestoreService.sanitizeProfileImage(user["profileImage"] ?? "") ?? "";
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: sanitizedProfileImage.isNotEmpty ? NetworkImage(sanitizedProfileImage) : null,
                    foregroundImage: sanitizedProfileImage.isNotEmpty && !Uri.tryParse(sanitizedProfileImage)!.hasAbsolutePath
                        ? const AssetImage("assets/default_profile.png") as ImageProvider
                        : null,
                    child: sanitizedProfileImage.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(
                    user["nickname"] ?? "알 수 없음",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: user["userId"] ?? "", // doc.id로 보장됨
                          nickname: user["nickname"] ?? "알 수 없음",
                          profileImage: sanitizedProfileImage,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}