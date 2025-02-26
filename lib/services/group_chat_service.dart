import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인한 유저 ID 가져오기
  String get currentUserId {
    return _auth.currentUser?.uid ?? "";
  }

  // 새로운 그룹 채팅방 생성
  Future<void> createGroupChat(String groupName, List<String> members) async {
    DocumentReference groupRef = _firestore.collection("group_chats").doc();

    await groupRef.set({
      "name": groupName,
      "members": members,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // 그룹 메시지 전송
  Future<void> sendMessage(String groupId, String text) async {
    if (currentUserId.isEmpty) return;

    await _firestore
        .collection("group_chats")
        .doc(groupId)
        .collection("messages")
        .add({
      "senderId": currentUserId,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // 특정 그룹의 메시지 가져오기
  Stream<QuerySnapshot> getMessages(String groupId) {
    return _firestore
        .collection("group_chats")
        .doc(groupId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // 유저가 참여한 그룹 목록 가져오기
  Stream<QuerySnapshot> getUserGroups() {
    return _firestore
        .collection("group_chats")
        .where("members", arrayContains: currentUserId)
        .snapshots();
  }
}
