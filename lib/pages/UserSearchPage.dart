import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'package:dartschat/pages/profile_detail_page.dart';
import 'package:dartschat/services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class UserSearchPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const UserSearchPage({super.key, required this.onLocaleChange});

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
        title: Text(
          AppLocalizations.of(context)!.userSearch,
          style: const TextStyle(color: Colors.white),
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
                hintText: AppLocalizations.of(context)!.searchHint,
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
                  return Center(
                      child: Text(AppLocalizations.of(context)!.errorLoadingUserList,
                          style: const TextStyle(color: Colors.redAccent)));
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
                  return Center(
                      child: Text(AppLocalizations.of(context)!.noSearchResults,
                          style: const TextStyle(color: Colors.black54)));
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
        ? userData["messageReceiveSetting"] ?? AppLocalizations.of(context)!.all_allowed
        : AppLocalizations.of(context)!.all_allowed;
    int rating = userData.containsKey("rating") ? userData["rating"] ?? 0 : 0;
    int totalViews = userData.containsKey("totalViews") ? userData["totalViews"] ?? 0 : 0;
    bool isPro = userData.containsKey("isPro") ? userData["isPro"] ?? false : false; // isPro 추가
    String rank = _calculateRank(totalViews, isPro);
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
          userData["nickname"] ?? AppLocalizations.of(context)!.unknownUser,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context)!.rank}: ",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                rank.startsWith("assets/")
                    ? Image.asset(
                  rank,
                  width: 20,
                  height: 20,
                )
                    : Text(
                  rank,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            Text(
              "${AppLocalizations.of(context)!.homeShop}: ${userData["homeShop"] ?? AppLocalizations.of(context)!.none}",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "${userData["dartBoard"] ?? AppLocalizations.of(context)!.none} | ${AppLocalizations.of(context)!.rating}: $rating",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "${AppLocalizations.of(context)!.messageSetting}: $messageSetting",
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
                nickname: userData["nickname"] ?? AppLocalizations.of(context)!.unknownUser,
                profileImages: profileImages,
                isCurrentUser: user.id == currentUserId,
                onLocaleChange: widget.onLocaleChange,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 등급 계산 (FriendInfoPage와 동일한 로직으로 수정)
  String _calculateRank(int totalViews, bool isPro) {
    if (isPro) return "assets/pro.png";
    if (totalViews >= 20000) return "assets/diamond.png";
    if (totalViews >= 15000) return "assets/emerald.png";
    if (totalViews >= 10000) return "assets/platinum_2.png";
    if (totalViews >= 5000) return "assets/platinum_1.png";
    if (totalViews >= 3200) return "assets/gold_2.png";
    if (totalViews >= 2200) return "assets/gold_1.png";
    if (totalViews >= 1800) return "assets/silver_2.png";
    if (totalViews >= 1200) return "assets/silver_1.png";
    if (totalViews >= 800) return "assets/bronze_3.png";
    if (totalViews >= 500) return "assets/bronze_2.png";
    if (totalViews >= 300) return "assets/bronze_1.png";
    return "💀"; // 300 미만은 해골 이모티콘
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