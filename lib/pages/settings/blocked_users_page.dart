import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/generated/app_localizations.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  _BlockedUsersPageState createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  Future<void> _unblockUser(String userId) async {
    try {
      await _firestoreService.unblockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.blockReleased)),
        );
      }
      _logger.i("User unblocked: userId: $userId");
    } catch (e) {
      _logger.e("Error unblocking user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorTogglingBlock}: $e")),
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
        title: Text(
          AppLocalizations.of(context)!.blockManagement,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
            return Center(
              child: Text(
                AppLocalizations.of(context)!.errorLoadingBlockedUsers,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          List<Map<String, dynamic>> blockedUsers = snapshot.data!;
          if (blockedUsers.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noBlockedUsers,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
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
                return const SizedBox.shrink();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("users").doc(userId).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink(); // 로딩 중일 때 아무것도 표시 안 함
                  }
                  if (userSnapshot.hasError) {
                    _logger.e("Error loading user data for $userId: ${userSnapshot.error}");
                    return const SizedBox.shrink(); // 오류 시 표시 안 함
                  }
                  if (!userSnapshot.data!.exists || userSnapshot.data!.data() == null) {
                    _logger.w("User data not found for $userId");
                    return const SizedBox.shrink(); // 데이터 없으면 표시 안 함
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String nickname = userData["nickname"] ?? user["nickname"] ?? AppLocalizations.of(context)!.unknownUser;
                  List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? user["profileImages"] ?? []);
                  String mainProfileImage = userData["mainProfileImage"] ?? user["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");
                  bool isActive = userData["isActive"] ?? true;

                  return _buildUserCard(nickname, mainProfileImage, isActive, onUnblock: () => _unblockUser(userId));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(String nickname, String? imageUrl, bool isActive, {VoidCallback? onUnblock}) {
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
        subtitle: !isActive
            ? Text(
          AppLocalizations.of(context)!.accountDeactivated,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.undo,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: onUnblock,
          tooltip: AppLocalizations.of(context)!.unblock,
        ),
      ),
    );
  }
}