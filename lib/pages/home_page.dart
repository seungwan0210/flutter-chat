import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'profile_detail_page.dart';
import 'UserSearchPage.dart';
import 'admin_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class HomePage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const HomePage({super.key, required this.onLocaleChange});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();
  String selectedBoardFilter = "all";
  String selectedRatingFilter = "all";
  static const int MAX_RATING = 30;

  Map<String, dynamic>? currentUserData;
  late Stream<DocumentSnapshot> profileStatsStream;

  List<String> ratingOptions = ["all"];
  String _messageSetting = "ALL";
  String _rank = "💀";
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _listenToCurrentUser();
    profileStatsStream = _getProfileStatsStream();
    ratingOptions = ["all", ...List.generate(MAX_RATING, (index) => (index + 1).toString())];
    _logger.i("HomePage initState called");
  }

  void _listenToCurrentUser() {
    String currentUserId = auth.currentUser!.uid;
    FirebaseFirestore.instance.collection("users").doc(currentUserId).snapshots().listen(
          (userDoc) {
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              currentUserData = userDoc.data() as Map<String, dynamic>;
              _messageSetting = currentUserData!["messageSetting"] ?? "all";
              _isPro = currentUserData!["isPro"] ?? false;
              _rank = _calculateRank(currentUserData!["totalViews"] ?? 0, _isPro);
            });
          }
          _logger.i("Current user data updated for UID: $currentUserId");
        }
      },
      onError: (e) {
        _logger.e("Error listening to current user data: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocalizations.of(context)!.errorLoadingUserData}: $e")),
          );
        }
      },
    );
  }

  Stream<DocumentSnapshot> _getProfileStatsStream() {
    String currentUserId = auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection("users").doc(currentUserId).snapshots();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _logger.e("Error loading user count: ${snapshot.error}");
              return Text(
                "${AppLocalizations.of(context)!.home} (${AppLocalizations.of(context)!.error})",
                style: const TextStyle(color: Colors.white),
              );
            }
            int userCount = snapshot.hasData
                ? snapshot.data!.docs
                .where((doc) {
              Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
              dynamic isActiveRaw = userData.containsKey("isActive") ? userData["isActive"] : true;
              bool isActive = isActiveRaw is bool
                  ? isActiveRaw
                  : isActiveRaw is String
                  ? isActiveRaw.toLowerCase() == "true"
                  : true;
              return isActive;
            })
                .length
                : 0;
            return Text(
              "${AppLocalizations.of(context)!.home} ($userCount)",
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSearchPage(onLocaleChange: widget.onLocaleChange),
                ),
              );
            },
          ),
          if (currentUserData != null && currentUserData!["role"] == "admin")
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          _buildProfileStats(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          _buildMyProfile(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          _buildFilterAndSearch(),
          const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.listenToBlockedUsers(),
              builder: (context, blockedSnapshot) {
                if (!blockedSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (blockedSnapshot.hasError) {
                  _logger.e("Error loading blocked users: ${blockedSnapshot.error}");
                  return Center(child: Text(AppLocalizations.of(context)!.errorLoadingBlockedUsers, style: const TextStyle(color: Colors.redAccent)));
                }

                var blockedIds = blockedSnapshot.data!.map((user) => user["blockedUserId"] as String).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection("users").snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      _logger.e("Error loading user list: ${snapshot.error}");
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.errorLoadingUserList,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }

                    var users = snapshot.data!.docs.where((user) {
                      if (user.id == auth.currentUser!.uid) return false;
                      if (blockedIds.contains(user.id)) return false;
                      Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
                      dynamic isActiveRaw = userData.containsKey("isActive") ? userData["isActive"] : true;
                      bool isActive = isActiveRaw is bool
                          ? isActiveRaw
                          : isActiveRaw is String
                          ? isActiveRaw.toLowerCase() == "true"
                          : true;
                      if (!isActive) return false;
                      String dartBoard = userData["dartBoard"] ?? "none";
                      int rating = userData["rating"] ?? 0;
                      return (selectedBoardFilter == "all" || dartBoard == selectedBoardFilter) &&
                          (selectedRatingFilter == "all" || rating.toString() == selectedRatingFilter);
                    }).toList();

                    _logger.i("Filtered user list length: ${users.length}");
                    return _buildUserList(users);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfile() {
    if (currentUserData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    bool isOnline = currentUserData!["status"] == "online";
    String nickname = currentUserData!["nickname"] ?? "unknown_user";
    String messageSetting = currentUserData!["messageSetting"] ?? "all";
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(currentUserData!["profileImages"] ?? []);
    String? mainProfileImage = currentUserData!["mainProfileImage"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailPage(
              userId: auth.currentUser!.uid,
              nickname: nickname,
              profileImages: profileImages,
              isCurrentUser: true,
              onLocaleChange: widget.onLocaleChange,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildProfileImage(mainProfileImage, profileImages, isOnline, _rank),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    "${AppLocalizations.of(context)!.homeShop}: ${currentUserData!["homeShop"] ?? AppLocalizations.of(context)!.none}",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    "${currentUserData!["dartBoard"] ?? AppLocalizations.of(context)!.none} | ${AppLocalizations.of(context)!.rating}: ${currentUserData!["rating"] ?? 0}",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    "${AppLocalizations.of(context)!.messageSetting}: ${AppLocalizations.of(context)!.translate(messageSetting)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    return ListView(
      children: [
        _buildUserSection(AppLocalizations.of(context)!.onlineUsers, users.where((user) => user["status"] == "online").toList()),
        const Divider(thickness: 0.5, color: Colors.grey, indent: 16, endIndent: 16),
        _buildUserSection(AppLocalizations.of(context)!.offlineUsers, users.where((user) => user["status"] == "offline").toList()),
      ],
    );
  }

  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        ...users.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    String currentUserId = auth.currentUser!.uid;
    bool isOnline = user["status"] == "online";
    Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
    String messageSetting = userData["messageSetting"] ?? "all";
    int rating = userData["rating"] ?? 0;
    int totalViews = userData["totalViews"] ?? 0;
    bool isPro = userData["isPro"] ?? false;
    String rank = _calculateRank(totalViews, isPro);
    List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
    String? mainProfileImage = userData["mainProfileImage"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        leading: _buildProfileImage(mainProfileImage, profileImages, isOnline, rank),
        title: Text(
          userData["nickname"] ?? AppLocalizations.of(context)!.unknownUser,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context)!.homeShop}: ${userData["homeShop"] ?? AppLocalizations.of(context)!.none}",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              "${userData["dartBoard"] ?? AppLocalizations.of(context)!.none} | ${AppLocalizations.of(context)!.rating}: $rating",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              "${AppLocalizations.of(context)!.messageSetting}: ${AppLocalizations.of(context)!.translate(messageSetting)}",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.message),
          onPressed: () async {
            // 메시지 설정에 따라 버튼 동작 제어
            if (messageSetting == 'messageBlocked') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.messageBlockedByUser)),
              );
              return;
            }
            if (messageSetting == 'friendsOnly') {
              DocumentSnapshot friendDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('friends')
                  .doc(_firestoreService.currentUserId)
                  .get();
              if (!friendDoc.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.friendsOnlyMessage)),
                );
                return;
              }
            }
            _logger.i("Navigating to chat with user: ${user.id}");
            // Navigator.push(...);
          },
        ),
        onTap: () {
          _firestoreService.incrementProfileViews(user.id);
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

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdownFilter(
                  selectedBoardFilter,
                  [
                    "all",
                    "dartlive",
                    "phoenix",
                    "granboard",
                    "homeboard",
                  ],
                      (newValue) => setState(() => selectedBoardFilter = newValue!),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _dropdownFilter(
                  selectedRatingFilter,
                  ratingOptions,
                      (newValue) => setState(() => selectedRatingFilter = newValue!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: profileStatsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          _logger.e("Error loading profile stats: ${snapshot.error}");
          return Center(
            child: Text(
              AppLocalizations.of(context)!.errorLoadingStats,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        var stats = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(AppLocalizations.of(context)!.total, "${stats["totalViews"] ?? 0}"),
              _buildStatItem(AppLocalizations.of(context)!.today, "${stats["todayViews"] ?? 0}"),
              _buildStatItem(AppLocalizations.of(context)!.rank, _rank),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String? mainProfileImage, List<Map<String, dynamic>> profileImages, bool isOnline, String rank) {
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
                ? Icon(
              Icons.person,
              size: 56,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: rank.startsWith("assets/")
                ? Image.asset(
              rank,
              width: 16,
              height: 16,
            )
                : Text(
              rank,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownFilter(String selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      onChanged: onChanged,
      items: items.isNotEmpty
          ? items.map((value) => DropdownMenuItem(value: value, child: Text(AppLocalizations.of(context)!.translate(value)))).toList()
          : [DropdownMenuItem(value: "all", child: Text(AppLocalizations.of(context)!.all))],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
    );
  }
}

extension AppLocalizationsExtension on AppLocalizations {
  String translate(String key) {
    switch (key) {
      case "all":
        return all;
      case "dartlive":
        return dartlive;
      case "phoenix":
        return phoenix;
      case "granboard":
        return granboard;
      case "homeboard":
        return homeboard;
      case "all_allowed":
        return all_allowed;
      case "friendsOnly":
        return friendsOnly;
      case "messageBlocked":
        return messageBlocked;
      default:
        return key;
    }
  }
}