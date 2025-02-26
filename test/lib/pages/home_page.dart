import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String selectedBoardFilter = "전체"; // ✅ 다트보드 필터 (기본값: 전체)
  String selectedOnlineFilter = "전체"; // ✅ 온라인/오프라인 필터 (기본값: 전체)
  String hopShopSearch = ""; // ✅ 홉샵 검색 텍스트

  @override
  Widget build(BuildContext context) {
    final String currentUserId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("홈"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          _buildFilterOptions(), // ✅ 필터 UI 추가
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var users = snapshot.data!.docs;

                // ✅ 본인(현재 로그인한 유저) 맨 위 정렬
                users.sort((a, b) {
                  if (a.id == currentUserId) return -1;
                  if (b.id == currentUserId) return 1;
                  return 0;
                });

                // ✅ 차단된 사용자 필터링
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(currentUserId)
                      .collection("blockedUsers")
                      .snapshots(),
                  builder: (context, blockedSnapshot) {
                    if (!blockedSnapshot.hasData) return _buildUserList(users, currentUserId);

                    var blockedUserIds = blockedSnapshot.data!.docs.map((doc) => doc.id).toSet();
                    var filteredUsers = users.where((user) => !blockedUserIds.contains(user.id)).toList();

                    return _buildUserList(filteredUsers, currentUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 필터 UI (다트보드, 온라인 상태, 홉샵 검색 추가)
  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ✅ 다트보드 필터
              DropdownButton<String>(
                value: selectedBoardFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBoardFilter = newValue!;
                  });
                },
                items: ["전체", "다트라이브", "피닉스", "그란보드", "홈보드"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              // ✅ 온라인/오프라인 필터
              DropdownButton<String>(
                value: selectedOnlineFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedOnlineFilter = newValue!;
                  });
                },
                items: ["전체", "온라인", "오프라인"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ✅ 홉샵 검색 필드 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  hopShopSearch = value.trim();
                });
              },
              decoration: InputDecoration(
                labelText: "홉샵 검색",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 사용자 목록 UI 생성 (필터 적용)
  Widget _buildUserList(List<QueryDocumentSnapshot> users, String currentUserId) {
    var filteredUsers = _applyFilters(users);

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        var user = filteredUsers[index];
        String userId = user.id;
        String nickname = user["nickname"] ?? "알 수 없음";
        String profileImage = user["profileImage"] ?? "";
        String status = user["status"] ?? "offline";
        String dartBoard = user.data().toString().contains('dartBoard') ? user["dartBoard"] : "다트 보드 정보 없음";
        int rating = user.data().toString().contains('rating') ? user["rating"] : 0;
        String hopShop = user.data().toString().contains('hopShop') ? user["hopShop"] : "없음";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty ? const Icon(Icons.person, size: 28) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status == "online" ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text("$dartBoard • 레이팅 $rating"),
          trailing: SizedBox(
            width: 120,
            child: Text(
              "홉샵: $hopShop",
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailPage(
                  userId: userId,
                  nickname: nickname,
                  profileImage: profileImage,
                  isCurrentUser: userId == currentUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ 필터 적용 함수 (다트보드 & 온라인 상태 & 홉샵 검색)
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> users) {
    var filteredUsers = users;

    // ✅ 다트보드 필터
    if (selectedBoardFilter != "전체") {
      filteredUsers = filteredUsers.where((user) => user["dartBoard"] == selectedBoardFilter).toList();
    }

    // ✅ 온라인/오프라인 필터
    if (selectedOnlineFilter == "온라인") {
      filteredUsers = filteredUsers.where((user) => user["status"] == "online").toList();
    } else if (selectedOnlineFilter == "오프라인") {
      filteredUsers = filteredUsers.where((user) => user["status"] == "offline").toList();
    }

    // ✅ 홉샵 검색 필터
    if (hopShopSearch.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        String hopShop = user.data().toString().contains('hopShop') ? user["hopShop"] : "없음";
        return hopShop.toLowerCase().contains(hopShopSearch.toLowerCase());
      }).toList();
    }

    return filteredUsers;
  }
}
