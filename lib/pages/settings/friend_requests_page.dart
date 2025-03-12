import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../profile_detail_page.dart'; // ProfileDetailPage 임포트

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
        _friendRequests.add({"userId": userId, "nickname": "알 수 없는 사용자", "profileImage": ""}); // 롤백
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
        _friendRequests.add({"userId": userId, "nickname": "알 수 없는 사용자", "profileImage": ""}); // 롤백
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
              String profileImage = _firestoreService.sanitizeProfileImage(request["profileImage"] ?? "") ?? "";

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                    foregroundImage: profileImage.isNotEmpty && !Uri.tryParse(profileImage)!.hasAbsolutePath
                        ? const AssetImage("assets/default_profile.png") as ImageProvider
                        : null,
                    child: profileImage.isEmpty
                        ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color)
                        : null,
                    onBackgroundImageError: profileImage.isNotEmpty
                        ? (exception, stackTrace) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("이미지 로드 오류: $exception")),
                      );
                      return null;
                    }
                        : null,
                  ),
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
                          profileImage: profileImage,
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
}