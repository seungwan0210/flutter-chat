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

  /// ✅ Firestore에서 현재 사용자의 채팅 목록 가져오기
  Stream<QuerySnapshot> _getChatRooms() {
    String currentUserId = _auth.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: currentUserId)
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
            return const Center(child: Text("참여한 채팅이 없습니다."));
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              var participants = List<String>.from(chatRoom["participants"]);

              // 상대방 ID 찾기
              String otherUserId = participants.firstWhere((id) => id != _auth.currentUser!.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String nickname = userData["nickname"] ?? "알 수 없음";
                  String profileImage = userData["profileImage"] ?? "";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : const AssetImage("assets/default_profile.png") as ImageProvider,
                    ),
                    title: Text(nickname),
                    subtitle: Text("최근 메시지: ${chatRoom["lastMessage"] ?? "메시지 없음"}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverId: otherUserId,
                            receiverName: nickname,
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
