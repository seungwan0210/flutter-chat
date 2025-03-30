import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import '../profile_detail_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class FriendRequestsPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const FriendRequestsPage({super.key, required this.onLocaleChange});

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
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorLoadingFriendRequests}: $error")),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestAccepted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorAcceptingFriendRequest}: $e")),
        );
      }
      setState(() {
        _friendRequests.add({"userId": userId, "nickname": AppLocalizations.of(context)!.unknownUser, "profileImages": []});
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
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestDeclined)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorDecliningFriendRequest}: $e")),
        );
      }
      setState(() {
        _friendRequests.add({"userId": userId, "nickname": AppLocalizations.of(context)!.unknownUser, "profileImages": []});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.friendRequests, // 다국어 키 사용
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.listenToFriendRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.errorLoadingFriendRequests,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noFriendRequests,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              );
            }

            List<Map<String, dynamic>> friendRequests = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 10),
              itemCount: friendRequests.length,
              itemBuilder: (context, index) {
                final request = friendRequests[index];
                String userId = request["userId"] ?? "";
                String nickname = request["nickname"] ?? AppLocalizations.of(context)!.unknownUser;
                List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(request["profileImages"] ?? []);
                String? mainProfileImage = request["mainProfileImage"];

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey.shade800,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildProfileImage(mainProfileImage, profileImages),
                    title: Text(
                      nickname,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _acceptFriend(userId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: () => _declineFriend(userId),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailPage(
                            userId: userId,
                            nickname: nickname,
                            profileImages: profileImages,
                            isCurrentUser: false,
                            onLocaleChange: widget.onLocaleChange, // onLocaleChange 전달
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
              ? const Icon(
            Icons.person,
            size: 56,
            color: Colors.grey,
          )
              : null,
          onBackgroundImageError: mainProfileImage != null && mainProfileImage.isNotEmpty
              ? (exception, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${AppLocalizations.of(context)!.imageLoadError}: $exception")),
            );
            return null;
          }
              : null,
        ),
      ),
    );
  }
}