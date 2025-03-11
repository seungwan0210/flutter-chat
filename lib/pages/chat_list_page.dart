import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Firestore에서 사용자가 참여한 모든 채팅방 가져오기
  Stream<QuerySnapshot> _getChatRooms() {
    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: _auth.currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("채팅 목록", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: Color(0xFF1A1A2E), // ✅ 배경 다크 블루 톤 적용
      body: Column(
        children: [
          /// ✅ 최상단 배너 추가
          _buildBanner(),

          /// ✅ 채팅 목록 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getChatRooms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var chatRooms = snapshot.data!.docs;

                if (chatRooms.isEmpty) {
                  return const Center(child: Text("채팅방이 없습니다.", style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    var chatRoom = chatRooms[index];
                    List participants = chatRoom["participants"];
                    Timestamp timestamp = chatRoom["timestamp"];
                    DateTime time = timestamp.toDate();

                    // 상대방 ID 찾기 (내 ID 제외)
                    String otherUserId = participants.firstWhere(
                          (id) => id != _auth.currentUser!.uid,
                      orElse: () => "",
                    );

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();

                        var userData = userSnapshot.data!;
                        String otherUserName = userData["nickname"] ?? "알 수 없음";
                        String profileImage = userData["profileImage"] ?? "";

                        // ✅ userData.data()를 안전하게 Map<String, dynamic>으로 변환 후 처리
                        String messageSetting = "모든 사람"; // 기본값 설정
                        var userDataMap = userData.data() as Map<String, dynamic>?; // Map으로 변환

                        if (userDataMap != null && userDataMap.containsKey("messageReceiveSetting")) {
                          messageSetting = userDataMap["messageReceiveSetting"] as String;
                        }

                        Map<String, dynamic>? friends = userDataMap;

                        // ✅ containsKey() 없이 안전한 친구 확인 코드
                        bool isFriend = false;
                        if (friends != null && friends["friends"] != null) {
                          var friendsList = friends["friends"];
                          if (friendsList is Map<String, dynamic>) {
                            isFriend = friendsList[_auth.currentUser!.uid] != null;
                          }
                        }

                        // ✅ "메시지 차단" 설정된 사용자는 리스트에서 숨김
                        if (messageSetting == "메시지 차단") {
                          return SizedBox();
                        }

                        // ✅ "친구만 허용" 설정 + 내가 친구가 아닐 경우 숨김
                        if (messageSetting == "친구만" && !isFriend) {
                          return SizedBox();
                        }

                        /// ✅ lastMessage를 Firestore에서 안전하게 가져오기
                        String lastMessage = "대화를 시작하세요!";
                        var chatData = chatRoom.data();
                        if (chatData != null && chatData is Map<String, dynamic> && chatData.containsKey('lastMessage')) {
                          lastMessage = chatData['lastMessage'] as String;
                        }

                        return Card(
                          color: Color(0xFF22223B), // ✅ 카드 다크 블루 톤 적용
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            leading: CircleAvatar(
                              backgroundImage: (profileImage.isNotEmpty)
                                  ? NetworkImage(profileImage)  // ✅ 프로필 이미지가 있는 경우
                                  : AssetImage("assets/default_profile.png") as ImageProvider, // ✅ 기본 이미지 적용
                              backgroundColor: Colors.blueAccent,
                              child: profileImage.isEmpty ? Text(otherUserName[0], style: TextStyle(color: Colors.white)) : null,
                            ),

                            title: Text(
                              otherUserName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              overflow: TextOverflow.ellipsis, // ✅ 오버플로우 방지
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // ✅ 오버플로우 방지
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(time), // ✅ 날짜 & 시간 표시
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                                ),
                                Text(
                                  _formatTime(time),
                                  style: TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatRoomId: chatRoom.id,
                                    chatPartnerImage: profileImage,
                                    chatPartnerName: otherUserName,
                                    receiverId: otherUserId,
                                    receiverName: otherUserName,
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

  /// ✅ 날짜 포맷 (오늘은 "오늘", 어제는 "어제", 나머지는 yyyy.MM.dd)
  String _formatDate(DateTime time) {
    DateTime now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return "오늘";
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return "어제";
    } else {
      return "${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}";
    }
  }

  /// ✅ 시간 포맷 (hh:mm AM/PM)
  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// ✅ 최상단 배너 추가
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {}, // ✅ 배너 클릭 시 동작 추가 가능
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
                offset: Offset(2, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage('assets/bulls_fighter.webp'), // ✅ 배너 이미지 추가
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
