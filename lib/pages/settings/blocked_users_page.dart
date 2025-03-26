import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Logger 추가
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  _BlockedUsersPageState createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger(); // Logger 인스턴스 추가

  Future<void> _unblockUser(String userId) async {
    try {
      await _firestoreService.unblockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("차단이 해제되었습니다.")),
        );
      }
      _logger.i("User unblocked: userId: $userId");
    } catch (e) {
      _logger.e("Error unblocking user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("차단 해제 중 오류가 발생했습니다: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _logger.i("BlockedUsersPage initState called");
  }

  @override
  void dispose() {
    _logger.i("BlockedUsersPage dispose called");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "차단 관리",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.listenToBlockedUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _logger.e("Error loading blocked users: ${snapshot.error}");
            return const Center(
              child: Text(
                "차단 목록을 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          List<Map<String, dynamic>> blockedUsers = snapshot.data!;
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text(
                "차단된 사용자가 없습니다.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              String userId = user["blockedUserId"] ?? "";
              if (userId.isEmpty) {
                _logger.w("Empty userId found in blocked users list");
                return const SizedBox();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("users").doc(userId).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("로딩 중...", style: TextStyle(color: Colors.black87)));
                  }
                  if (userSnapshot.hasError) {
                    _logger.e("Error loading user data for $userId: ${userSnapshot.error}");
                    return const ListTile(title: Text("정보 로드 오류", style: TextStyle(color: Colors.black87)));
                  }
                  if (!userSnapshot.data!.exists) {
                    return const ListTile(title: Text("사용자 데이터 없음", style: TextStyle(color: Colors.black87)));
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null) {
                    return const ListTile(title: Text("사용자 데이터 없음", style: TextStyle(color: Colors.black87)));
                  }

                  String nickname = userData["nickname"] ?? user["nickname"] ?? "알 수 없는 사용자";
                  List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? user["profileImages"] ?? []);
                  String mainProfileImage = userData["mainProfileImage"] ?? user["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");
                  bool isActive = userData["isActive"] ?? true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: GestureDetector(
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
                                initialIndex: mainProfileImage.isNotEmpty && validImageUrls.contains(mainProfileImage)
                                    ? validImageUrls.indexOf(mainProfileImage)
                                    : 0,
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
                          child: mainProfileImage.isEmpty
                              ? Icon(
                            Icons.person,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            size: 40,
                          )
                              : null,
                          onBackgroundImageError: mainProfileImage.isNotEmpty
                              ? (exception, stackTrace) {
                            _logger.e("Image load error for $mainProfileImage: $exception");
                            return null;
                          }
                              : null,
                        ),
                      ),
                      title: Text(
                        nickname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: !isActive
                          ? const Text(
                        "비활성화된 계정",
                        style: TextStyle(color: Colors.redAccent),
                      )
                          : null,
                      trailing: IconButton(
                        icon: Icon(
                          Icons.block,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _unblockUser(userId),
                      ),
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