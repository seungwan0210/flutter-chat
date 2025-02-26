import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 현재 로그인한 유저 ID 가져오기
  String get currentUserId {
    return _auth.currentUser?.uid ?? "";
  }

  // 채팅방 ID 생성 (유저1-유저2 순으로 정렬)
  String _generateChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // 항상 같은 순서로 정렬하여 일관된 ID 생성
    return ids.join("_");
  }

  // 메시지 전송 + 푸시 알림 발송
  Future<void> sendMessage(String receiverId, String text) async {
    if (currentUserId.isEmpty) return; // 로그인 상태 확인

    String chatRoomId = _generateChatRoomId(currentUserId, receiverId);

    // Firestore에 메시지 저장
    await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 푸시 알림 전송
    await _sendPushNotification(receiverId, text);
  }

  // 채팅 메시지 가져오기 (Stream)
  Stream<QuerySnapshot> getMessages(String receiverId) {
    if (currentUserId.isEmpty) {
      return const Stream.empty(); // 로그인 상태가 아닐 경우 빈 스트림 반환
    }

    String chatRoomId = _generateChatRoomId(currentUserId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 푸시 알림 전송
  Future<void> _sendPushNotification(String receiverId, String message) async {
    // Firestore에서 상대방의 FCM 토큰 가져오기
    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(receiverId).get();

    if (!userDoc.exists || !userDoc.data().toString().contains("fcmToken")) return;

    String? token = userDoc['fcmToken'];
    if (token == null || token.isEmpty) return;

    // FCM 서버 키 설정 (Firebase 콘솔에서 발급받아야 함)
    const String serverKey = "YOUR_FIREBASE_SERVER_KEY";

    final body = {
      "to": token,
      "notification": {
        "title": "새로운 메시지",
        "body": message,
        "sound": "default",
      },
      "priority": "high",
    };

    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode(body),
    );
  }
}
