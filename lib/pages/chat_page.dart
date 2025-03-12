import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerName;
  final String chatPartnerImage;
  final String receiverId;
  final String receiverName;

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
  final FirestoreService _firestoreService = FirestoreService();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = currentUser!.uid;
    String receiverId = widget.receiverId;
    String messageText = _messageController.text.trim();
    Timestamp now = Timestamp.now();

    try {
      DocumentSnapshot receiverSnapshot = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();

      if (!receiverSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("상대방 정보를 찾을 수 없습니다.")),
        );
        return;
      }

      var receiverData = receiverSnapshot.data() as Map<String, dynamic>? ?? {};
      String messageSetting = receiverData.containsKey("messageReceiveSetting")
          ? receiverData["messageReceiveSetting"]
          : "모든 사람";
      Map<String, dynamic>? friends = receiverData.containsKey("friends")
          ? receiverData["friends"] as Map<String, dynamic>
          : {};

      if (messageSetting == "메시지 차단") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("상대방이 메시지를 받을 수 없습니다.")),
        );
        return;
      } else if (messageSetting == "친구만" && !friends.containsKey(senderId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구만 메시지를 보낼 수 있습니다.")),
        );
        return;
      }

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

      await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).update({
        'lastMessage': messageText,
        'timestamp': now,
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("메시지 전송 중 오류가 발생했습니다: $e")),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.black,
        title: Text(
          widget.chatPartnerName,
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "메시지를 불러오는 중 오류가 발생했습니다.",
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }
                var messages = snapshot.data!.docs;
                String lastDate = "";

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              dateFormatted,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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

  /// 채팅 메시지 버블 UI (시간을 메시지 옆에 표시)
  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 18,
              backgroundImage: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isNotEmpty
                  ? NetworkImage(_firestoreService.sanitizeProfileImage(widget.chatPartnerImage))
                  : null,
              foregroundImage: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isNotEmpty &&
                  !Uri.tryParse(_firestoreService.sanitizeProfileImage(widget.chatPartnerImage))!.hasAbsolutePath
                  ? const AssetImage("assets/default_profile.png") as ImageProvider
                  : null,
              child: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isMe ? Colors.amber[100] : Colors.grey[200],
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
              ]
                  : [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 입력창 UI
  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor ?? Colors.white,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor ?? Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).iconTheme.color ?? Colors.grey.shade600),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지 입력',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor ?? Colors.amber[700]),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// 날짜를 "2025년 3월 8일 토요일" 형식으로 변환
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("yyyy년 M월 d일 EEEE", "ko_KR").format(date);
  }

  /// 시간을 "오전/오후 HH:mm" 형식으로 변환
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("a h:mm", "ko_KR").format(date).replaceAll("AM", "오전").replaceAll("PM", "오후");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}