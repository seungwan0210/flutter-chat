import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({super.key});

  @override
  _FriendManagementPageState createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();

  /// Firestore에서 친구 목록 실시간 로드
  Stream<List<Map<String, dynamic>>> listenToFriends() {
    return _firestoreService.listenToFriends();
  }

  /// 친구 삭제 기능
  Future<void> removeFriend(String userId) async {
    try {
      await _firestoreService.removeFriend(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구가 삭제되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구 삭제 중 오류가 발생했습니다: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "친구 관리",
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
        stream: listenToFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "친구 목록을 불러오는 중 오류가 발생했습니다.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "아직 친구가 없습니다. 친구를 추가해보세요!",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            );
          }

          List<Map<String, dynamic>> friends = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              String userId = friend["userId"] ?? "ID 없음";
              String nickname = friend["nickname"] ?? "알 수 없는 사용자";

              // Firestore에서 최신 사용자 데이터 가져오기
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("users").doc(userId).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const ListTile(title: Text("로딩 중..."));
                  if (userSnapshot.hasError) return const ListTile(title: Text("정보 로드 오류"));
                  if (!userSnapshot.data!.exists) return const ListTile(title: Text("사용자 데이터 없음"));

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null) return const ListTile(title: Text("사용자 데이터 없음"));

                  List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
                  String mainProfileImage = userData["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");
                  nickname = userData["nickname"] ?? "알 수 없는 사용자";

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: mainProfileImage.isNotEmpty ? NetworkImage(mainProfileImage) : null,
                        child: mainProfileImage.isEmpty
                            ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color)
                            : null,
                        onBackgroundImageError: mainProfileImage.isNotEmpty
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
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Text(
                        "@$userId",
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.error),
                        onPressed: () => removeFriend(userId),
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