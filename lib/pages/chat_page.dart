import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dartschat/generated/app_localizations.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/profile_detail_page.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerName;
  final String chatPartnerImage;
  final String receiverId;
  final String receiverName;
  final void Function(Locale) onLocaleChange;

  const ChatPage({
    required this.chatRoomId,
    required this.chatPartnerName,
    required this.chatPartnerImage,
    required this.receiverId,
    required this.receiverName,
    required this.onLocaleChange,
    super.key,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead(); // 페이지 로드 시 읽음 처리
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();

    try {
      await _firestoreService.sendMessage(widget.receiverId, messageText);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppLocalizations.of(context)!.errorSendingMessage}: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _markMessagesAsRead() async {
    try {
      await _firestoreService.markMessagesAsRead(widget.chatRoomId);
      // 읽음 처리 후 배지 업데이트 확인 (선택적 피드백)
      int unreadCount = await _firestoreService.getTotalUnreadCount(currentUser!.uid); // _getTotalUnreadCount -> getTotalUnreadCount
      if (unreadCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.allMessagesRead),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppLocalizations.of(context)!.errorLoadingMessages}: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchMessages,
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        )
            : Row(
          children: [
            GestureDetector(
              onTap: () {
                _firestoreService.incrementProfileViews(widget.receiverId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailPage(
                      userId: widget.receiverId,
                      nickname: widget.chatPartnerName,
                      profileImages: [],
                      isCurrentUser: false,
                      onLocaleChange: widget.onLocaleChange,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isNotEmpty
                    ? NetworkImage(_firestoreService.sanitizeProfileImage(widget.chatPartnerImage))
                    : null,
                child: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.chatPartnerName,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
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
                      AppLocalizations.of(context)!.errorLoadingMessages,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }
                var messages = snapshot.data!.docs;
                String lastDate = "";

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (_searchQuery.isNotEmpty) {
                  messages = messages.where((message) {
                    var messageData = message.data() as Map<String, dynamic>;
                    String text = messageData['content']?.toLowerCase() ?? "";
                    return text.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

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
                          (message.data() != null && (message.data() as Map<String, dynamic>).containsKey('content'))
                              ? message['content']
                              : AppLocalizations.of(context)!.noMessage,
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

  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    _firestoreService.incrementProfileViews(widget.receiverId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: widget.receiverId,
                          nickname: widget.chatPartnerName,
                          profileImages: [],
                          isCurrentUser: false,
                          onLocaleChange: widget.onLocaleChange,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isNotEmpty
                        ? NetworkImage(_firestoreService.sanitizeProfileImage(widget.chatPartnerImage))
                        : null,
                    child: _firestoreService.sanitizeProfileImage(widget.chatPartnerImage).isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.chatPartnerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMe) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
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
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                    ),
                  ),
                  if (!isMe) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                hintText: AppLocalizations.of(context)!.enterMessage,
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("yyyy년 M월 d일 EEEE", "ko_KR").format(date);
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat("a h:mm", "ko_KR")
        .format(date)
        .replaceAll("AM", AppLocalizations.of(context)!.am)
        .replaceAll("PM", AppLocalizations.of(context)!.pm);
  }
}