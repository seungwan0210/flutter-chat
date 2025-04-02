import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'chat_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:logger/logger.dart';

class ChatListPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const ChatListPage({super.key, required this.onLocaleChange});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredChatRooms = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _filterChatRooms();
    });
    _createTestChatRoom();
  }

  Future<void> _filterChatRooms() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredChatRooms = [];
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: _auth.currentUser!.uid)
          .orderBy("lastMessageTime", descending: true)
          .get();

      List<Map<String, dynamic>> chatRooms = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'chatId': doc.id,
          'participants': List<String>.from(data['participants']),
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': data['lastMessageTime'],
          'unreadCount': data['unreadCount'] ?? {},
        };
      }).toList();

      List<Map<String, dynamic>> filtered = [];
      for (var chatRoom in chatRooms) {
        String otherUserId = chatRoom['participants'].firstWhere((id) => id != _auth.currentUser!.uid);
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection("users").doc(otherUserId).get();
        if (!userSnapshot.exists) continue;

        var userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
        String nickname = userData["nickname"]?.toLowerCase() ?? "";
        if (nickname.contains(_searchQuery.toLowerCase())) {
          filtered.add(chatRoom);
        }
      }

      setState(() {
        _filteredChatRooms = filtered;
      });
    } catch (e) {
      _logger.e("채팅방 필터링 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.errorSearching}: $e")),
      );
      setState(() {
        _filteredChatRooms = [];
      });
    }
  }

  void _createTestChatRoom() async {
    String currentUserId = _auth.currentUser!.uid;
    String testUserId = "testUserId"; // 실제 다른 사용자 UID로 교체
    String chatId = _firestoreService.generateChatId(currentUserId, testUserId);
    await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
      "participants": [currentUserId, testUserId],
      "lastMessage": "테스트 메시지",
      "lastMessageTime": FieldValue.serverTimestamp(),
      "unreadCount": {currentUserId: 0, testUserId: 1},
    });
    _logger.i("테스트 채팅방 생성됨: $chatId");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchNickname,
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        )
            : Text(
          AppLocalizations.of(context)!.chat,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filteredChatRooms = [];
                }
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                // 새 채팅 시작 기능 추가 가능
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // 설정 페이지로 이동 가능
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildBanner(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getChatList().distinct(), // 중복 업데이트 방지
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  _logger.i("채팅 리스트 데이터 로딩 중");
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  _logger.e("채팅 리스트 로드 오류: ${snapshot.error}");
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.errorLoadingChatList,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                var chatRooms = snapshot.data!;
                _logger.i("총 채팅방 수: ${chatRooms.length}");

                if (chatRooms.isEmpty) {
                  _logger.i("채팅방 없음");
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noChatRooms,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }

                List<Map<String, dynamic>> displayChatRooms = _searchQuery.isEmpty ? chatRooms : _filteredChatRooms;
                _logger.i("표시할 채팅방 수: ${displayChatRooms.length}");

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: displayChatRooms.length,
                  itemBuilder: (context, index) {
                    var chatRoom = displayChatRooms[index];
                    String chatId = chatRoom['chatId'];
                    String otherUserId = chatRoom['otherUserId'];
                    String lastMessage = chatRoom['lastMessage'];
                    int unreadCount = chatRoom['unreadCount'];
                    Timestamp? timestamp = chatRoom['lastMessageTime'];
                    DateTime time = timestamp?.toDate() ?? DateTime.now();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection("users").doc(otherUserId).snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();
                        if (userSnapshot.hasError) return const SizedBox();

                        var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                        String otherUserName = userData["nickname"] ?? AppLocalizations.of(context)!.unknownUser;
                        List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
                        String mainProfileImage = userData["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");

                        String messageSetting = userData["messageReceiveSetting"] ?? "all_allowed";

                        bool isFriend = false;
                        if (userData.containsKey("friends")) {
                          var friends = userData["friends"] as Map<String, dynamic>?;
                          isFriend = friends != null && friends.containsKey(_auth.currentUser!.uid);
                        }

                        if (messageSetting == "messageBlocked") return const SizedBox();
                        if (messageSetting == "friendsOnly" && !isFriend) return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
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
                                    ? Text(
                                  otherUserName.isNotEmpty ? otherUserName[0] : "U",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            title: Text(
                              otherUserName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              lastMessage.isEmpty ? AppLocalizations.of(context)!.startChat : lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDate(time),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(time),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 12), // 간격 조정
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatRoomId: chatId,
                                    chatPartnerImage: mainProfileImage,
                                    chatPartnerName: otherUserName,
                                    receiverId: otherUserId,
                                    receiverName: otherUserName,
                                    onLocaleChange: widget.onLocaleChange,
                                  ),
                                ),
                              ).then((_) {
                                setState(() {}); // 새로고침
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime time) {
    DateTime now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return AppLocalizations.of(context)!.today;
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return "${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}";
    }
  }

  String _formatTime(DateTime time) {
    String period = time.hour < 12 ? AppLocalizations.of(context)!.am : AppLocalizations.of(context)!.pm;
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return "$period $hour:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
                offset: const Offset(2, 4),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/bulls_fighter.webp'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}