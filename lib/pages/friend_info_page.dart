import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 언어팩 임포트
import 'chat_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/pages/settings/blocked_users_page.dart';
import 'package:dartschat/pages/main_page.dart';

class FriendInfoPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final List<Map<String, dynamic>> receiverImages;
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const FriendInfoPage({
    super.key,
    required this.receiverId,
    required this.receiverImages,
    required this.receiverName,
    required this.onLocaleChange,
  });

  @override
  _FriendInfoPageState createState() => _FriendInfoPageState();
}

class _FriendInfoPageState extends State<FriendInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  Map<String, dynamic>? _friendData;
  bool _isFavorite = false;
  int totalViews = 0;
  int dailyViews = 0;
  String _rank = "💀";
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isBlocked = false;
  bool _isPro = false; // isDiamond -> isPro
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadFriendInfo();
    _checkFavoriteStatus();
    _firestoreService.listenToBlockedStatus(widget.receiverId).listen(
          (isBlocked) {
        if (mounted) {
          setState(() {
            _isBlocked = isBlocked;
          });
        }
      },
      onError: (e) => _logger.e("Error listening to blocked status: $e"),
    );
    _logger.i("FriendInfoPage initState called for receiverId: ${widget.receiverId}");
  }

  @override
  void dispose() {
    _logger.i("FriendInfoPage dispose called for receiverId: ${widget.receiverId}");
    super.dispose();
  }

  Future<void> _loadFriendInfo() async {
    try {
      Map<String, dynamic>? friendData = await _firestoreService.getUserData(userId: widget.receiverId);
      if (friendData != null) {
        if (mounted) {
          setState(() {
            _friendData = friendData;
            totalViews = _friendData!["totalViews"] ?? 0;
            dailyViews = _friendData!["todayViews"] ?? 0;
            _isPro = _friendData!["isPro"] ?? false; // isDiamond -> isPro
            _rank = _calculateRank(totalViews, _isPro);
            _profileImages = _firestoreService.sanitizeProfileImages(_friendData!["profileImages"] ?? []);
            _mainProfileImage = _friendData!["mainProfileImage"];
            _isActive = _friendData!["isActive"] ?? true;
            _isLoading = false;
          });
        }
        _logger.i("Friend info loaded for receiverId: ${widget.receiverId}");
      } else {
        if (mounted) {
          setState(() {
            _friendData = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.friendInfoNotFound)),
          );
        }
      }
    } catch (e) {
      _logger.e("Error loading friend info: $e");
      if (mounted) {
        setState(() {
          _friendData = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorLoadingFriendInfo}: $e")),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      DocumentSnapshot favoriteDoc = await _firestoreService.firestore
          .collection("users")
          .doc(currentUserId)
          .collection("favorites")
          .doc(widget.receiverId)
          .get();
      if (mounted) {
        setState(() {
          _isFavorite = favoriteDoc.exists;
        });
      }
      _logger.i("Favorite status checked: isFavorite=$_isFavorite for receiverId: ${widget.receiverId}");
    } catch (e) {
      _logger.e("Error checking favorite status: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotAddDeactivatedToFavorites)),
        );
      }
      return;
    }

    try {
      String currentUserId = _auth.currentUser!.uid;
      if (_isFavorite) {
        await _firestoreService.firestore
            .collection("users")
            .doc(currentUserId)
            .collection("favorites")
            .doc(widget.receiverId)
            .delete();
        _logger.i("Removed from favorites: receiverId: ${widget.receiverId}");
      } else {
        await _firestoreService.firestore
            .collection("users")
            .doc(currentUserId)
            .collection("favorites")
            .doc(widget.receiverId)
            .set({});
        _logger.i("Added to favorites: receiverId: ${widget.receiverId}");
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      _logger.e("Error toggling favorite status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorTogglingFavorite}: $e")),
        );
      }
    }
  }

  void _startChat() {
    if (!_isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotMessageDeactivated)),
        );
      }
      return;
    }

    String chatRoomId = _getChatRoomId(_auth.currentUser!.uid, widget.receiverId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          chatPartnerName: widget.receiverName,
          chatPartnerImage: _mainProfileImage ?? "",
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
          onLocaleChange: widget.onLocaleChange, // onLocaleChange 전달
        ),
      ),
    );
  }

  String _getChatRoomId(String userId, String receiverId) {
    return userId.hashCode <= receiverId.hashCode ? '$userId\_$receiverId' : '$receiverId\_$userId';
  }

  Future<void> _removeFriend() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFriend),
        content: Text(AppLocalizations.of(context)!.confirmRemoveFriend),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.remove, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.removeFriend(widget.receiverId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.friendRemoved)));
        }
        _logger.i("Friend removed: receiverId: ${widget.receiverId}");
      } catch (e) {
        _logger.e("Error removing friend: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppLocalizations.of(context)!.errorRemovingFriend}: $e")));
        }
      }
    }
  }

  Future<void> _blockFriend() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.blockUser),
        content: Text(AppLocalizations.of(context)!.confirmBlockUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.block, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.removeFriend(widget.receiverId);
        await _firestoreService.toggleBlockUser(widget.receiverId, widget.receiverName, _profileImages);
        await _firestoreService.firestore
            .collection("users")
            .doc(_auth.currentUser!.uid)
            .collection("favorites")
            .doc(widget.receiverId)
            .delete();

        bool isActive = await _firestoreService.isUserActive(widget.receiverId);
        if (mounted) {
          setState(() {
            _isActive = isActive;
            _isBlocked = true;
          });
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(
                initialIndex: 0,
                onLocaleChange: widget.onLocaleChange,
              ),
            ),
                (Route<dynamic> route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.userBlocked)));
        }
        _logger.i("Friend blocked and removed: receiverId: ${widget.receiverId}");
      } catch (e) {
        _logger.e("Error blocking friend: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppLocalizations.of(context)!.errorBlockingFriend}: $e")));
        }
      }
    }
  }

  String _calculateRank(int totalViews, bool isPro) {
    if (isPro) return "assets/pro.png"; // isDiamond -> isPro
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.friendInfo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isBlocked ? Icons.block : Icons.block_outlined,
              color: _isBlocked ? Colors.red : Colors.white,
            ),
            onPressed: _blockFriend,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendData == null
          ? Center(child: Text(AppLocalizations.of(context)!.friendInfoNotFound, style: const TextStyle(fontSize: 16, color: Colors.white)))
          : SingleChildScrollView(
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
            _friendData!["nickname"] ?? AppLocalizations.of(context)!.unknownUser,
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
            color: Colors.black.withOpacity(0.2),
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
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(Icons.store, AppLocalizations.of(context)!.homeShop, _friendData!["homeShop"] ?? AppLocalizations.of(context)!.none),
          _infoTile(Icons.star, AppLocalizations.of(context)!.rating, _friendData!["rating"]?.toString() ?? AppLocalizations.of(context)!.none),
          _infoTile(Icons.sports_esports, AppLocalizations.of(context)!.dartBoard, _friendData!["dartBoard"] ?? AppLocalizations.of(context)!.none),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(Icons.chat, AppLocalizations.of(context)!.sendMessage, const LinearGradient(colors: [Colors.amber, Colors.orange]), _startChat),
          const SizedBox(height: 12),
          _buildActionButton(
            _isFavorite ? Icons.star : Icons.star_border,
            AppLocalizations.of(context)!.favorites,
            _isFavorite ? const LinearGradient(colors: [Colors.amber, Colors.orange]) : const LinearGradient(colors: [Colors.grey, Colors.grey]),
            _toggleFavorite,
          ),
          const SizedBox(height: 12),
          _buildActionButton(Icons.person_remove, AppLocalizations.of(context)!.removeFriend, const LinearGradient(colors: [Colors.redAccent, Colors.red]), _removeFriend),
          const SizedBox(height: 12),
          _buildActionButton(Icons.block, AppLocalizations.of(context)!.block, const LinearGradient(colors: [Colors.grey, Colors.grey]), _blockFriend),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, LinearGradient gradient, VoidCallback onPressed) {
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
}