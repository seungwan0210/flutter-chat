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
                List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(user["profileImages"] ?? []);
                String mainProfileImage = user["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");
                return ListTile(
                  leading: _buildProfileImage(mainProfileImage, profileImages),
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
                          profileImages: profileImages, // 객체 리스트 전달
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

  /// 프로필 이미지 (이미지 리스트 지원)
  Widget _buildProfileImage(String mainProfileImage, List<Map<String, dynamic>> profileImages) {
    return GestureDetector(
      onTap: () {
        if (profileImages.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImagePage(
                imageUrls: profileImages.map((img) => img['url'] as String).toList(),
                initialIndex: profileImages.indexWhere((img) => img['url'] == mainProfileImage),
              ),
            ),
          );
        }
      },
      child: CircleAvatar(
        backgroundImage: mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
        child: mainProfileImage.isEmpty ? const Icon(Icons.person) : null,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// 전체 화면 이미지 보기 페이지 (여러 장 넘겨보기 지원)
class FullScreenImagePage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                height: double.infinity,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error, color: Colors.white));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}