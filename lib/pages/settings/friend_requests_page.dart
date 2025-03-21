import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile_detail_page.dart'; // 경로 수정: lib/pages/ 디렉토리에 있다고 가정
import '../../services/firestore_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _friendRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  /// Firestore에서 친구 요청 목록 실시간 감지
  void _loadFriendRequests() {
    _firestoreService.listenToFriendRequests().listen((requests) {
      if (mounted) {
        setState(() {
          _friendRequests = requests;
        });
      }
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 목록을 불러오는 중 오류 발생: $error")),
        );
      }
    });
  }

  /// 친구 요청 승인 (Firestore 업데이트 & 즉시 UI 반영)
  Future<void> _acceptFriend(String userId) async {
    if (userId.isEmpty) return;

    setState(() {
      _friendRequests.removeWhere((request) => request["userId"] == userId);
    });

    try {
      await _firestoreService.acceptFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 요청을 승인했습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 승인 중 오류 발생: $e")),
        );
      }
      setState(() {
        _friendRequests.add({"userId": userId, "nickname": "알 수 없는 사용자", "profileImages": []}); // 롤백
      });
    }
  }

  /// 친구 요청 거절 (Firestore 업데이트 & 즉시 UI 반영)
  Future<void> _declineFriend(String userId) async {
    if (userId.isEmpty) return;

    setState(() {
      _friendRequests.removeWhere((request) => request["userId"] == userId);
    });

    try {
      await _firestoreService.declineFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 요청을 거절했습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 요청 거절 중 오류 발생: $e")),
        );
      }
      setState(() {
        _friendRequests.add({"userId": userId, "nickname": "알 수 없는 사용자", "profileImages": []}); // 롤백
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "친구 요청",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.listenToFriendRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "친구 요청 목록을 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "받은 친구 요청이 없습니다. 친구를 기다려보세요!",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            );
          }

          List<Map<String, dynamic>> friendRequests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: friendRequests.length,
            itemBuilder: (context, index) {
              final request = friendRequests[index];
              String userId = request["userId"] ?? "";
              String nickname = request["nickname"] ?? "알 수 없는 사용자";
              List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(request["profileImages"] ?? []);
              String mainProfileImage = request["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildProfileImage(mainProfileImage, profileImages),
                  title: Text(
                    nickname,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _acceptFriend(userId),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _declineFriend(userId),
                      ),
                    ],
                  ),
                  onTap: () {
                    // ProfileDetailPage로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: userId,
                          nickname: nickname,
                          profileImages: profileImages, // 객체 리스트 전달
                          isCurrentUser: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
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
        radius: 28,
        backgroundImage: mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
        child: mainProfileImage.isEmpty ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color) : null,
        onBackgroundImageError: mainProfileImage.isNotEmpty
            ? (exception, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("이미지 로드 오류: $exception")),
          );
          return null;
        }
            : null,
      ),
    );
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