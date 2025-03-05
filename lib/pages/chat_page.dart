import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  /// ✅ Firestore에서 채팅 메시지 가져오기
  Stream<QuerySnapshot> _getMessages() {
    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: _auth.currentUser!.uid)
        .where("participants", arrayContains: widget.receiverId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// ✅ 채팅 메시지 Firestore에 저장
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = _auth.currentUser!.uid;
    String message = _messageController.text.trim();
    Timestamp timestamp = Timestamp.now();

    DocumentReference chatRoomRef = FirebaseFirestore.instance.collection("chats").doc();

    chatRoomRef.set({
      "participants": [senderId, widget.receiverId],
      "lastMessage": message,
      "timestamp": timestamp,
    });

    FirebaseFirestore.instance.collection("messages").add({
      "chatRoomId": chatRoomRef.id,
      "senderId": senderId,
      "receiverId": widget.receiverId,
      "message": message,
      "timestamp": timestamp,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message["senderId"] == _auth.currentUser!.uid;

                    return Container(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message["message"], style: const TextStyle(fontSize: 16)),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// ✅ 메시지 입력창 UI
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "메시지 입력..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
