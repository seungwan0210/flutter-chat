import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({super.key});

  @override
  _FriendManagementPageState createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  Stream<List<Map<String, dynamic>>> listenToFriends() {
    return _firestoreService.listenToFriends();
  }

  Future<void> removeFriend(String userId) async {
    try {
      await _firestoreService.removeFriend(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRemoved)),
        );
      }
      _logger.i("Friend removed: userId: $userId");
    } catch (e) {
      _logger.e("Error removing friend: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorRemovingFriend}: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _logger.i("FriendManagementPage initState called");
  }

  @override
  void dispose() {
    _logger.i("FriendManagementPage dispose called");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.friendManagement,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: listenToFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _logger.e("Error loading friends: ${snapshot.error}");
            return Center(
              child: Text(
                AppLocalizations.of(context)!.errorLoadingFriendInfo,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noFriendsAdded,
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
              String userId = friend["userId"] ?? "";
              if (userId.isEmpty) {
                _logger.w("Empty userId found in friends list");
                return const SizedBox.shrink();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("users").doc(userId).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  if (userSnapshot.hasError) {
                    _logger.e("Error loading user data for $userId: ${userSnapshot.error}");
                    return const SizedBox.shrink();
                  }
                  if (!userSnapshot.data!.exists || userSnapshot.data!.data() == null) {
                    _logger.w("User data not found for $userId");
                    return const SizedBox.shrink();
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String nickname = userData["nickname"] ?? friend["nickname"] ?? AppLocalizations.of(context)!.unknownUser;
                  List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? friend["profileImages"] ?? []);
                  String mainProfileImage = userData["mainProfileImage"] ?? friend["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");

                  return _buildFriendCard(nickname, mainProfileImage, onRemove: () => removeFriend(userId));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFriendCard(String nickname, String? imageUrl, {VoidCallback? onRemove}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: GestureDetector(
          onTap: imageUrl != null && imageUrl.isNotEmpty
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  imageUrls: [imageUrl],
                  initialIndex: 0,
                ),
              ),
            );
          }
              : null,
          child: CircleAvatar(
            radius: 30,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(
              Icons.person,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 40,
            )
                : null,
            onBackgroundImageError: imageUrl != null && imageUrl.isNotEmpty
                ? (exception, stackTrace) {
              _logger.e("Image load error for $imageUrl: $exception");
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
        trailing: IconButton(
          icon: Icon(
            Icons.person_remove,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: onRemove,
          tooltip: AppLocalizations.of(context)!.removeFriend,
        ),
      ),
    );
  }
}