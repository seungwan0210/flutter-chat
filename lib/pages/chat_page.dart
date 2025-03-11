import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ✅ 날짜 형식 변환을 위해 추가

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerName;
  final String chatPartnerImage;
  final String receiverId;
  final String receiverName; // ✅ 첫 번째 코드에서 추가된 필드 유지

  ChatPage({
    required this.chatRoomId,
    required this.chatPartnerName,
    required this.chatPartnerImage,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = currentUser!.uid;
    String receiverId = widget.receiverId;
    String messageText = _messageController.text.trim();
    Timestamp now = Timestamp.now();

    // ✅ Firestore에서 상대방의 메시지 설정 가져오기 (오류 방지) - 첫 번째 코드 유지
    DocumentSnapshot receiverSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(receiverId).get();

    if (!receiverSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("상대방 정보를 찾을 수 없습니다.")),
      );
      return;
    }

    // ✅ userData를 안전하게 Map<String, dynamic>으로 변환
    var receiverData = receiverSnapshot.data() as Map<String, dynamic>? ?? {};

    // ✅ messageReceiveSetting 필드가 없으면 기본값 "모든 사람" 설정
    String messageSetting = receiverData.containsKey("messageReceiveSetting")
        ? receiverData["messageReceiveSetting"]
        : "모든 사람";

    // ✅ 친구 목록 가져오기 (오류 방지)
    Map<String, dynamic>? friends = receiverData.containsKey("friends")
        ? receiverData["friends"] as Map<String, dynamic>
        : {};

    // ✅ 메시지 차단 조건 확인
    if (messageSetting == "메시지 차단") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("상대방이 메시지를 받을 수 없습니다.")),
      );
      return;
    } else if (messageSetting == "친구만" && !friends.containsKey(senderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구만 메시지를 보낼 수 있습니다.")),
      );
      return;
    }

    // ✅ Firestore에 메시지 저장
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': now,
    });

    // ✅ Firestore의 chats/{chatRoomId} 문서에 lastMessage 업데이트
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).update({
      'lastMessage': messageText, // ✅ 최신 메시지 저장
      'timestamp': now, // ✅ 최근 메시지 시간 저장 (채팅 리스트 정렬용)
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () { // ✅ 약간의 딜레이 추가
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // ✅ 맨 아래로 이동
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
            onPressed: () {}, // ✅ 첫 번째 코드에서 유지된 actions
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
                String lastDate = ""; // ✅ 날짜 헤더 변수

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(); // ✅ 프레임 렌더링 후 스크롤
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == currentUser?.uid;
                    Timestamp? timestamp = message['timestamp'];
                    String timeFormatted = _formatTime(timestamp);
                    String dateFormatted = _formatDate(timestamp);

                    bool showDateHeader = lastDate != dateFormatted;
                    if (showDateHeader) {
                      lastDate = dateFormatted;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              dateFormatted,
                              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        _buildMessageBubble(
                          (message.data() != null && (message.data() as Map<String, dynamic>).containsKey('text'))
                              ? message['text']
                              : "[메시지 없음]",
                          isMe,
                          timeFormatted,
                        ),
                      ],
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

  /// ✅ 채팅 메시지 버블 UI (시간을 메시지 옆에 표시)
  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            widget.chatPartnerImage.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(widget.chatPartnerImage),
              radius: 18,
            )
                : CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.white),
              radius: 18,
            ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: isMe
                  ? [
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 6), // ✅ 시간과 메시지 간격
                Text(message, style: TextStyle(fontSize: 16, color: Colors.black)),
              ]
                  : [
                Text(message, style: TextStyle(fontSize: 16, color: Colors.black)),
                SizedBox(width: 6), // ✅ 메시지와 시간 간격
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 메시지 입력창 UI
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

  /// ✅ 날짜를 "2025년 3월 8일 토요일" 형식으로 변환
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("yyyy년 M월 d일 EEEE", "ko_KR").format(date); // ✅ 한글 요일 포함
  }

  /// ✅ 시간을 "오전/오후 HH:mm" 형식으로 변환
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("a h:mm", "ko_KR").format(date).replaceAll("AM", "오전").replaceAll("PM", "오후");
  }
}