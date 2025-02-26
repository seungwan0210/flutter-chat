import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'friends_page.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  _FriendSearchPageState createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<String> allFriends = []; // ✅ 전체 유저 목록
  List<String> filteredFriends = [];
  List<String> myFriends = []; // ✅ 내 친구 목록 (파이어베이스에서 가져오기)

  @override
  void initState() {
    super.initState();
    _fetchFriendsFromFirebase();
    _fetchMyFriends();
    _searchController.addListener(_filterFriends);
  }

  /// ✅ Firebase에서 전체 유저 목록 가져오기
  Future<void> _fetchFriendsFromFirebase() async {
    FirebaseFirestore.instance.collection('users').get().then((snapshot) {
      setState(() {
        allFriends = snapshot.docs.map((doc) => doc['nickname'].toString()).toList();
      });
    });
  }

  /// ✅ Firebase에서 현재 유저의 친구 목록 가져오기
  Future<void> _fetchMyFriends() async {
    String currentUserId = "현재 로그인한 유저 ID"; // 🛑 실제 로그인된 유저 ID 가져와야 함

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends') // ✅ 친구 리스트 컬렉션
        .get()
        .then((snapshot) {
      setState(() {
        myFriends = snapshot.docs.map((doc) => doc['nickname'].toString()).toList();
      });
    });
  }

  void _filterFriends() {
    String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredFriends = [];
      });
      return;
    }

    setState(() {
      filteredFriends = allFriends.where((friend) {
        return _containsKoreanInitials(friend, query) || friend.toLowerCase().contains(query);
      }).toList();
    });
  }

  bool _containsKoreanInitials(String name, String query) {
    String initials = _getKoreanInitials(name);
    return initials.contains(query);
  }

  String _getKoreanInitials(String text) {
    List<String> initials = [];
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (_isKorean(char)) {
        initials.add(_getInitial(char));
      } else {
        initials.add(char.toLowerCase());
      }
    }
    return initials.join();
  }

  bool _isKorean(String char) {
    return RegExp(r'^[가-힣]').hasMatch(char);
  }

  String _getInitial(String char) {
    List<String> initials = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ',
      'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    int base = 44032;
    int index = (char.codeUnitAt(0) - base) ~/ 588;
    return initials[index];
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
        title: const Text("친구 검색", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "친구 검색",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendsPage()),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _searchController.text.isEmpty
                ? const SizedBox()
                : filteredFriends.isEmpty
                ? const Center(child: Text("검색 결과가 없습니다."))
                : ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredFriends[index]),
                  onTap: () {
                    String friendName = filteredFriends[index];

                    if (myFriends.contains(friendName)) {
                      // ✅ 친구 목록에 있으면 FriendInfoPage로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendInfoPage(friendName: friendName),
                        ),
                      );
                    } else {
                      // ✅ 친구 목록에 없으면 ProfileDetailPage로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailPage(friendName: friendName),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ 친구 프로필 페이지 (친구일 경우)
class FriendInfoPage extends StatelessWidget {
  final String friendName;

  const FriendInfoPage({super.key, required this.friendName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        backgroundColor: Colors.greenAccent,
      ),
      body: Center(child: Text("$friendName의 프렌드 정보 페이지")),
    );
  }
}

/// ✅ 상세 프로필 페이지 (친구가 아닐 경우)
class ProfileDetailPage extends StatelessWidget {
  final String friendName;

  const ProfileDetailPage({super.key, required this.friendName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(child: Text("$friendName의 프로필 디테일 페이지")),
    );
  }
}
