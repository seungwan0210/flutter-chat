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
      appBar: AppBar(title: const Text("채팅 목록")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getChatRooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return const Center(child: Text("채팅방이 없습니다."));
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              List participants = chatRoom["participants"];
              String lastMessage = chatRoom["lastMessage"] ?? "대화를 시작하세요!";
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
                  if (!userSnapshot.hasData) return const SizedBox();

                  var userData = userSnapshot.data!;
                  String otherUserName = userData["nickname"] ?? "알 수 없음";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(otherUserName[0]), // 첫 글자 표시
                    ),
                    title: Text(otherUserName),
                    subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text("${time.hour}:${time.minute}"), // 시간 표시
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverId: otherUserId,
                            receiverName: otherUserName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
