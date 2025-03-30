import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'chat_page.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class ChatListPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const ChatListPage({super.key, required this.onLocaleChange});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<QueryDocumentSnapshot> _filteredChatRooms = [];

  /// Firestore에서 사용자가 참여한 모든 채팅방 가져오기
  Stream<QuerySnapshot> _getChatRooms() {
    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: _auth.currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _filterChatRooms();
    });
  }

  /// 채팅방 필터링
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
          .orderBy("timestamp", descending: true)
          .get();

      List<QueryDocumentSnapshot> chatRooms = snapshot.docs;
      List<QueryDocumentSnapshot> filtered = [];

      for (var chatRoom in chatRooms) {
        List participants = chatRoom["participants"];
        String otherUserId = participants.firstWhere(
              (id) => id != _auth.currentUser!.uid,
          orElse: () => "",
        );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.errorSearching}: $e")),
      );
      setState(() {
        _filteredChatRooms = [];
      });
    }
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
          /// 최상단 배너 추가
          _buildBanner(),

          /// 채팅 목록 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getChatRooms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.errorLoadingChatList,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                var chatRooms = snapshot.data!.docs;

                if (chatRooms.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noChatRooms,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // 검색 결과가 있으면 필터링된 리스트 사용, 없으면 전체 리스트 사용
                List<QueryDocumentSnapshot> displayChatRooms = _searchQuery.isEmpty ? chatRooms : _filteredChatRooms;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: displayChatRooms.length,
                  itemBuilder: (context, index) {
                    var chatRoom = displayChatRooms[index];
                    List participants = chatRoom["participants"];
                    Timestamp timestamp = chatRoom["timestamp"];
                    DateTime time = timestamp.toDate();

                    // 상대방 ID 찾기 (내 ID 제외)
                    String otherUserId = participants.firstWhere(
                          (id) => id != _auth.currentUser!.uid,
                      orElse: () => "",
                    );

                    // Firestore에서 상대방 데이터 가져오기 (Stream 사용)
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection("users").doc(otherUserId).snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();
                        if (userSnapshot.hasError) return const SizedBox();

                        var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                        String otherUserName = userData["nickname"] ?? AppLocalizations.of(context)!.unknownUser;
                        List<Map<String, dynamic>> profileImages = _firestoreService.sanitizeProfileImages(userData["profileImages"] ?? []);
                        String mainProfileImage = userData["mainProfileImage"] ?? (profileImages.isNotEmpty ? profileImages.last['url'] : "");

                        // messageReceiveSetting 처리
                        String messageSetting = userData["messageReceiveSetting"] ?? AppLocalizations.of(context)!.all_allowed;

                        // 친구 목록 확인
                        bool isFriend = false;
                        if (userData.containsKey("friends")) {
                          var friends = userData["friends"] as Map<String, dynamic>?;
                          isFriend = friends != null && friends.containsKey(_auth.currentUser!.uid);
                        }

                        // "메시지 차단" 설정된 사용자는 리스트에서 숨김
                        if (messageSetting == AppLocalizations.of(context)!.messageBlocked) {
                          return const SizedBox();
                        }

                        // "친구만 허용" 설정 + 내가 친구가 아닐 경우 숨김
                        if (messageSetting == AppLocalizations.of(context)!.friendsOnly && !isFriend) {
                          return const SizedBox();
                        }

                        // lastMessage 처리
                        String lastMessage = AppLocalizations.of(context)!.startChat;
                        var chatData = chatRoom.data() as Map<String, dynamic>;
                        if (chatData.containsKey('lastMessage')) {
                          lastMessage = chatData['lastMessage'] as String;
                        }

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
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54,
                              ),
                            ),
                            trailing: Column(
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatRoomId: chatRoom.id,
                                    chatPartnerImage: mainProfileImage,
                                    chatPartnerName: otherUserName,
                                    receiverId: otherUserId,
                                    receiverName: otherUserName,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷 (오늘은 "오늘", 어제는 "어제", 나머지는 yyyy.MM.dd)
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

  /// 시간 포맷 (hh:mm AM/PM)
  String _formatTime(DateTime time) {
    String period = time.hour < 12 ? AppLocalizations.of(context)!.am : AppLocalizations.of(context)!.pm;
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return "$period $hour:${time.minute.toString().padLeft(2, '0')}";
  }

  /// 최상단 배너 추가
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