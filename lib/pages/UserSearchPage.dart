import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/pages/profile_detail_page.dart';
import 'package:dartschat/services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "유저 검색",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "닉네임 / 홈샵 검색",
                hintStyle: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return const Center(child: Text("사용자 목록을 불러오는 중 오류가 발생했습니다.", style: TextStyle(color: Colors.redAccent)));
                }

                var users = snapshot.data!.docs.where((user) {
                  if (user.id == auth.currentUser!.uid) return false;
                  Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
                  String nickname = userData["nickname"]?.toLowerCase() ?? "";
                  String homeShop = userData["homeShop"]?.toLowerCase() ?? "";
                  return (_searchText.isEmpty ||
                      nickname.contains(_searchText.toLowerCase()) ||
                      homeShop.contains(_searchText.toLowerCase()));
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.black54)));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    String currentUserId = auth.currentUser!.uid;
    bool isOnline = user["status"] == "online";
    Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
    String messageSetting = userData.containsKey("messageReceiveSetting")
        ? userData["messageReceiveSetting"] ?? "전체 허용"
        : "전체 허용";
    int rating = userData.containsKey("rating") ? userData["rating"] ?? 0 : 0;
    int totalViews = userData.containsKey("totalViews") ? userData["totalViews"] ?? 0 : 0;
    String rank = _calculateRank(totalViews);
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
    String? mainProfileImage = userData["mainProfileImage"];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: _buildProfileImage(mainProfileImage, profileImages, isOnline),
        title: Text(
          userData["nickname"] ?? "알 수 없는 사용자",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "등급: $rank",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            Text(
              "홈샵: ${userData["homeShop"] ?? "없음"}",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "${userData["dartBoard"] ?? "없음"} | 레이팅: $rating",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "메시지 설정: $messageSetting",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetailPage(
                userId: user.id,
                nickname: userData["nickname"] ?? "알 수 없음",
                profileImages: profileImages,
                isCurrentUser: user.id == currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 등급 계산
  String _calculateRank(int totalViews) {
    if (totalViews >= 500) return "다이아몬드";
    if (totalViews >= 200) return "플래티넘";
    if (totalViews >= 100) return "골드";
    if (totalViews >= 50) return "실버";
    return "브론즈";
  }

  /// 프로필 이미지 (이미지 리스트 지원)
  Widget _buildProfileImage(String? mainProfileImage, List<Map<String, dynamic>> profileImages, bool isOnline) {
    return Stack(
      children: [
        GestureDetector(
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
          child: CircleAvatar(
            radius: 28,
            backgroundImage: mainProfileImage != null && mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
            child: mainProfileImage == null || mainProfileImage.isEmpty
                ? const Icon(
              Icons.person,
              size: 56,
              color: Colors.grey,
            )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
      ],
    );
  }
}