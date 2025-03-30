import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 언어팩 임포트
import '../services/firestore_service.dart';
import 'chat_page.dart';
import 'play_summary_page.dart';
import 'profile_page.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final List<Map<String, dynamic>> profileImages;
  final bool isCurrentUser;
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const ProfileDetailPage({
    super.key,
    required this.userId,
    required this.nickname,
    required this.profileImages,
    required this.isCurrentUser,
    required this.onLocaleChange, // 필수 매개변수로 추가
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  bool _isBlocked = false;
  bool _isFriend = false;
  bool _isRequestPending = false;
  int _rating = 0;
  String _dartBoard = "정보 없음";
  String _homeShop = "없음";
  int totalViews = 0;
  int dailyViews = 0;
  String messageSetting = "전체 허용";
  String? _errorMessage;
  String _rank = "💀";
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isPro = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
    _loadUserInfo();
    if (!widget.isCurrentUser) {
      _increaseProfileView(widget.userId);
    }
    _logger.i("ProfileDetailPage initState called for userId: ${widget.userId}");
  }

  @override
  void dispose() {
    _logger.i("ProfileDetailPage dispose called for userId: ${widget.userId}");
    super.dispose();
  }

  String _getDateString(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

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
    return "💀";
  }

  Future<void> _checkFriendStatus() async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("friends")
          .doc(widget.userId)
          .get();
      if (mounted) {
        setState(() {
          _isFriend = friendDoc.exists;
        });
      }

      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("friendRequests")
          .doc(currentUserId)
          .get();
      if (mounted) {
        setState(() {
          _isRequestPending = requestDoc.exists;
        });
      }

      _logger.i("Friend status checked: isFriend=$_isFriend, isRequestPending=$_isRequestPending");
    } catch (e) {
      _logger.e("Error checking friend status: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorCheckingFriendStatus}: $e";
        });
      }
    }
  }

  Future<void> _increaseProfileView(String viewedUserId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      if (currentUserId == viewedUserId) return;

      DocumentReference profileRef = FirebaseFirestore.instance.collection("users").doc(viewedUserId);
      DocumentSnapshot profileSnapshot = await profileRef.get();
      if (!profileSnapshot.exists || !(profileSnapshot["isActive"] ?? true)) return;

      await _firestoreService.incrementProfileViews(viewedUserId);
      _logger.i("Profile view increased for userId: $viewedUserId");

      DocumentSnapshot updatedProfile = await profileRef.get();
      if (updatedProfile.exists) {
        Map<String, dynamic>? updatedData = updatedProfile.data() as Map<String, dynamic>?;
        if (updatedData != null && mounted) {
          setState(() {
            totalViews = updatedData["totalViews"] ?? 0;
            dailyViews = updatedData["todayViews"] ?? 0;
            _isPro = updatedData["isPro"] ?? false;
            _rank = _calculateRank(totalViews, _isPro);
          });
        }
      }
    } catch (e) {
      _logger.e("Error increasing profile view: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorIncreasingProfileViews}: $e";
        });
      }
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData(userId: widget.userId);
      if (userData != null) {
        if (mounted) {
          setState(() {
            _rating = userData["rating"] ?? 0;
            _dartBoard = userData["dartBoard"] ?? AppLocalizations.of(context)!.none;
            _homeShop = userData["homeShop"] ?? AppLocalizations.of(context)!.none;
            totalViews = userData["totalViews"] ?? 0;
            dailyViews = userData["todayViews"] ?? 0;
            messageSetting = userData["messageReceiveSetting"] ?? AppLocalizations.of(context)!.all_allowed;
            _isPro = userData["isPro"] ?? false;
            _rank = _calculateRank(totalViews, _isPro);
            _profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
            _mainProfileImage = userData["mainProfileImage"];
            _isActive = userData["isActive"] ?? true;
          });
        }
        _logger.i("User info loaded for userId: ${widget.userId}");
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.userInfoNotFound;
          });
        }
      }
    } catch (e) {
      _logger.e("Error loading user info: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingUserInfo}: $e";
        });
      }
    }
  }

  Future<void> _toggleBlockUser() async {
    try {
      await _firestoreService.toggleBlockUser(widget.userId, widget.nickname, _profileImages);
      if (mounted) {
        setState(() {
          _isBlocked = !_isBlocked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBlocked ? AppLocalizations.of(context)!.userBlocked : AppLocalizations.of(context)!.blockReleased)),
        );
      }
      _logger.i("Block status toggled: isBlocked=$_isBlocked for userId: ${widget.userId}");

      bool isActive = await _firestoreService.isUserActive(widget.userId);
      if (mounted) {
        setState(() {
          _isActive = isActive;
        });
      }
    } catch (e) {
      _logger.e("Error toggling block status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorTogglingBlock}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileDetail,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildProfileStats(),
            const SizedBox(height: 16),
            _buildProfileInfo(),
            const SizedBox(height: 16),
            if (!_isActive)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.accountDeactivated,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            if (_isActive) _buildActionButtons(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 80, bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              List<String> validImageUrls = _profileImages
                  .map((img) => img['url'] as String?)
                  .where((url) => url != null && url.isNotEmpty)
                  .cast<String>()
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    imageUrls: validImageUrls,
                    initialIndex: _mainProfileImage != null && validImageUrls.contains(_mainProfileImage)
                        ? validImageUrls.indexOf(_mainProfileImage!)
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
                radius: 60,
                backgroundColor: Colors.black,
                backgroundImage: _mainProfileImage != null && _mainProfileImage!.isNotEmpty ? NetworkImage(_mainProfileImage!) : null,
                child: _mainProfileImage == null || _mainProfileImage!.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.nickname,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(AppLocalizations.of(context)!.total, "$totalViews"),
          _buildStatItem(AppLocalizations.of(context)!.today, "$dailyViews"),
          _buildStatItem(AppLocalizations.of(context)!.rank, _rank),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        title == AppLocalizations.of(context)!.rank && value.startsWith("assets/")
            ? Image.asset(
          value,
          width: 24,
          height: 24,
        )
            : Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.store, AppLocalizations.of(context)!.homeShop, _homeShop),
          _buildInfoRow(Icons.star, AppLocalizations.of(context)!.rating, _rating > 0 ? "$_rating" : AppLocalizations.of(context)!.notRegistered),
          _buildInfoRow(Icons.sports_esports, AppLocalizations.of(context)!.dartBoard, _dartBoard),
          _buildInfoRow(Icons.message, AppLocalizations.of(context)!.messageSetting, messageSetting),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.settings,
              label: AppLocalizations.of(context)!.profileSettings,
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(onLocaleChange: widget.onLocaleChange),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.timeline,
              label: AppLocalizations.of(context)!.todayPlaySummary,
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaySummaryPage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.message,
              label: AppLocalizations.of(context)!.sendMessage,
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              onPressed: _isActive
                  ? () async {
                String senderId = _auth.currentUser!.uid;
                String receiverId = widget.userId;

                QuerySnapshot chatRoomQuery = await FirebaseFirestore.instance
                    .collection("chats")
                    .where("participants", arrayContains: senderId)
                    .get();

                String chatRoomId;
                DocumentReference? existingChatRoom;

                for (var doc in chatRoomQuery.docs) {
                  List participants = doc["participants"];
                  if (participants.contains(receiverId)) {
                    existingChatRoom = doc.reference;
                    break;
                  }
                }

                if (existingChatRoom != null) {
                  chatRoomId = existingChatRoom.id;
                } else {
                  chatRoomId = _getChatRoomId(senderId, receiverId);
                  await FirebaseFirestore.instance.collection("chats").doc(chatRoomId).set({
                    "participants": [senderId, receiverId],
                    "lastMessage": "",
                    "timestamp": Timestamp.now(),
                  });
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatRoomId: chatRoomId,
                      chatPartnerName: widget.nickname,
                      chatPartnerImage: _mainProfileImage ?? "",
                      receiverId: receiverId,
                      receiverName: widget.nickname,
                      onLocaleChange: widget.onLocaleChange,
                    ),
                  ),
                );
              }
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.cannotMessageDeactivated)),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<bool>(
              stream: _firestoreService.listenToBlockedStatus(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  _logger.e("Error loading blocked status: ${snapshot.error}");
                  return Text(
                    AppLocalizations.of(context)!.errorLoadingBlockedStatus,
                    style: const TextStyle(color: Colors.redAccent),
                  );
                }

                _isBlocked = snapshot.data ?? false;
                return Column(
                  children: [
                    _buildFriendActionButton(),
                    const SizedBox(height: 12),
                    _buildBlockActionButton(),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFriendActionButton() {
    if (_isBlocked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppLocalizations.of(context)!.blockedUser,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (_isFriend) {
      return _buildActionButton(
        icon: Icons.person_remove,
        label: AppLocalizations.of(context)!.removeFriend,
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.red],
        ),
        onPressed: _removeFriend,
      );
    } else if (_isRequestPending) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppLocalizations.of(context)!.requested,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return _buildActionButton(
        icon: Icons.person_add,
        label: AppLocalizations.of(context)!.addFriend,
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        onPressed: _isActive
            ? _sendFriendRequest
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cannotAddDeactivated)),
          );
        },
      );
    }
  }

  Widget _buildBlockActionButton() {
    return _buildActionButton(
      icon: _isBlocked ? Icons.block : Icons.block_outlined,
      label: _isBlocked ? AppLocalizations.of(context)!.unblock : AppLocalizations.of(context)!.block,
      gradient: _isBlocked
          ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
          : const LinearGradient(colors: [Colors.redAccent, Colors.red]),
      onPressed: _toggleBlockUser,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _firestoreService.sendFriendRequest(widget.userId);
      if (mounted) {
        setState(() {
          _isRequestPending = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestSent)),
        );
      }
      _logger.i("Friend request sent to userId: ${widget.userId}");
    } catch (e) {
      _logger.e("Error sending friend request: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorSendingFriendRequest}: $e")),
        );
      }
    }
  }

  Future<void> _removeFriend() async {
    try {
      await _firestoreService.removeFriend(widget.userId);
      if (mounted) {
        setState(() {
          _isFriend = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRemoved)),
        );
      }
      _logger.i("Friend removed: userId: ${widget.userId}");
    } catch (e) {
      _logger.e("Error removing friend: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorRemovingFriend}: $e")),
        );
      }
    }
  }
}