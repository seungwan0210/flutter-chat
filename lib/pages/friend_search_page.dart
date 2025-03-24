import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  _FriendSearchPageState createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _friendIds = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    _firestoreService.listenToFriends().listen((friends) {
      setState(() {
        _friendIds = friends.map((friend) => friend["userId"] as String).toList();
      });
    });
  }

  /// 검색 실행 (친구로 등록된 사용자만)
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

      List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['userId'] = doc.id; // 문서 ID를 userId로 추가
        return data;
      }).toList();

      // 친구 목록에 포함된 사용자만 필터링
      results = results.where((user) => _friendIds.contains(user['userId'])).toList();

      setState(() {
        _searchResults = results;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "친구 검색",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80, left: 16.0, right: 16.0, bottom: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "닉네임 검색",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                ),
                onChanged: _searchUsers,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var user = _searchResults[index];
                  List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(user["profileImages"] ?? []);
                  String? mainProfileImage = user["mainProfileImage"];
                  return ListTile(
                    leading: _buildProfileImage(mainProfileImage, profileImages),
                    title: Text(
                      user["nickname"] ?? "알 수 없음",
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      _firestoreService.incrementProfileViews(user["userId"]);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailPage(
                            userId: user["userId"] ?? "",
                            nickname: user["nickname"] ?? "알 수 없음",
                            profileImages: profileImages,
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
      ),
    );
  }

  /// 프로필 이미지 (이미지 리스트 지원)
  Widget _buildProfileImage(String? mainProfileImage, List<Map<String, dynamic>> profileImages) {
    return GestureDetector(
      onTap: () {
        List<String> validImageUrls = profileImages
            .map((img) => img['url'] as String?)
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImagePage(
              imageUrls: validImageUrls,
              initialIndex: mainProfileImage != null && validImageUrls.contains(mainProfileImage)
                  ? validImageUrls.indexOf(mainProfileImage)
                  : 0,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.black,
          backgroundImage: mainProfileImage != null && mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
          child: mainProfileImage == null || mainProfileImage.isEmpty
              ? Icon(
            Icons.person,
            size: 56,
            color: Colors.grey,
          )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}