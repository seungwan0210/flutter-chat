import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerName;
  final String chatPartnerImage;
  final String receiverId;
  final String receiverName; // ✅ 추가

  ChatPage({required this.chatRoomId, required this.chatPartnerName, required this.chatPartnerImage, required this.receiverName, required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = FirebaseAuth.instance.currentUser!.uid;
    String receiverId = widget.receiverId;
    String messageText = _messageController.text.trim();
    Timestamp now = Timestamp.now();

    // ✅ Firestore에서 상대방의 메시지 설정 가져오기
    DocumentSnapshot receiverSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(receiverId).get();

    if (!receiverSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("상대방 정보를 찾을 수 없습니다.")),
      );
      return;
    }

    String messageSetting = receiverSnapshot["messageReceiveSetting"] ?? "모든 사람";
    Map<String, dynamic>? friends = receiverSnapshot.data() as Map<String, dynamic>?;

    // ✅ 메시지 차단 조건 확인
    if (messageSetting == "메시지 차단") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("상대방이 메시지를 받을 수 없습니다.")),
      );
      return;
    } else if (messageSetting == "친구만" && !(friends?["friends"]?.containsKey(senderId) ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구만 메시지를 보낼 수 있습니다.")),
      );
      return;
    }

    // ✅ Firestore에 메시지 저장
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).collection('messages').add({
      'text': messageText,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': now,
    });

    // ✅ Firestore의 chats/{chatRoomId} 문서에 lastMessage 업데이트
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).update({
      'lastMessage': messageText,  // ✅ 최신 메시지 저장
      'timestamp': now,  // ✅ 최근 메시지 시간 저장 (채팅 리스트 정렬용)
    });

    _messageController.clear();
    _scrollToBottom();
  }




  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(widget.chatPartnerName, style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == currentUser?.uid;
                    return _buildMessageBubble(
                      (message.data() != null && (message.data() as Map<String, dynamic>).containsKey('text'))
                          ? message['text']
                          : "[메시지 없음]", // ✅ 메시지가 없을 경우 기본값 제공
                      isMe,
                      (message.data() != null && (message.data() as Map<String, dynamic>).containsKey('timestamp'))
                          ? message['timestamp']
                          : null, // ✅ timestamp도 null 체크 후 처리
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, Timestamp? timestamp) {
    String time = timestamp != null
        ? '${DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000).hour}:${DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000).minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) CircleAvatar(backgroundImage: NetworkImage(widget.chatPartnerImage), radius: 18),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isMe ? Colors.yellow : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(fontSize: 16, color: Colors.black)),
                SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지 입력',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
