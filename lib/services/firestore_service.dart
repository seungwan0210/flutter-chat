import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Firestore 인스턴스 Getter (오류 해결)
  FirebaseFirestore get firestore => _firestore;

  /// ✅ 현재 로그인된 유저의 UID 가져오기
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> incrementProfileViews(String userId) async {
    String? currentUserId = this.currentUserId;
    if (currentUserId == null || currentUserId == userId) return;

    DocumentReference userRef = _firestore.collection("users").doc(userId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      int totalViews = userData["totalViews"] ?? 0;
      int todayViews = userData["todayViews"] ?? 0;
      DateTime lastViewDate = userData["lastViewDate"]?.toDate() ?? DateTime.now();
      DateTime now = DateTime.now();

      if (now.difference(lastViewDate).inDays >= 1) {
        todayViews = 1; // ✅ 새로운 날이면 todayViews 초기화
      } else {
        todayViews += 1;
      }

      transaction.update(userRef, {
        "totalViews": totalViews + 1,
        "todayViews": todayViews,
        "lastViewDate": now,
      });
    });

    print("✅ 프로필 조회수 업데이트 완료: $userId");
  }

  /// ✅ 특정 유저 차단 여부 확인
  Future<bool> isUserBlocked(String targetUserId) async {
    String? currentUserId = this.currentUserId;
    if (currentUserId == null) return false;

    DocumentSnapshot blockDoc = await _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .doc(targetUserId)
        .get();

    return blockDoc.exists;
  }

  Future<void> toggleBlockUser(String targetUserId, String nickname, String profileImage) async {
    String? currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    DocumentReference blockRef = _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .doc(targetUserId);

    DocumentSnapshot blockCheck = await blockRef.get();

    if (blockCheck.exists) {
      await blockRef.delete();
      print("✅ 차단 해제: $targetUserId");
    } else {
      await blockRef.set({
        "blockedUserId": targetUserId,
        "nickname": nickname,  // ✅ 차단할 유저의 닉네임 저장
        "profileImage": profileImage,  // ✅ 차단할 유저의 프로필 이미지 저장
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ 차단 완료: $targetUserId");
    }
  }

  /// ✅ 특정 유저 정보 가져오기
  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) return null;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // 🔹 `friendCount` 필드가 없으면 기본값 0 추가
      userData["friendCount"] = userData.containsKey("friendCount") ? userData["friendCount"] : 0;

      return userData;
    } catch (e) {
      print("❌ Firestore에서 유저 정보를 불러오는 중 오류 발생: $e");
      return null;
    }
  }

  /// ✅ 현재 로그인된 유저 정보 가져오기
  Future<Map<String, dynamic>?> getUserData() async {
    String? userId = currentUserId;
    if (userId == null) {
      print("❌ 오류: 로그인되지 않은 상태에서 유저 정보를 요청했습니다.");
      return null;
    }
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) return null;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // 🔹 `friendCount` 필드가 없으면 기본값 0 추가
      userData["friendCount"] = userData.containsKey("friendCount") ? userData["friendCount"] : 0;

      return userData;
    } catch (e) {
      print("❌ Firestore에서 유저 정보를 불러오는 중 오류 발생: $e");
      return null;
    }
  }

  /// ✅ Firestore에서 유저 정보 실시간 감지 (UI 자동 업데이트)
  Stream<Map<String, dynamic>?> listenToUserData() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }
    return _firestore.collection("users").doc(userId).snapshots().map(
          (snapshot) => snapshot.data() as Map<String, dynamic>?,
    );
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    String? currentUserId = this.currentUserId;
    if (currentUserId == null) return;

    DocumentSnapshot userDoc = await _firestore.collection("users").doc(currentUserId).get();
    if (!userDoc.exists) return;

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String nickname = userData["nickname"] ?? "알 수 없는 사용자";
    String profileImage = userData["profileImage"] ?? "";

    DocumentReference requestRef = _firestore
        .collection("users")
        .doc(targetUserId)
        .collection("friendRequests")
        .doc(currentUserId);

    await requestRef.set({
      "fromUserId": currentUserId,
      "nickname": nickname, // ✅ 친구 요청 보낼 때 nickname 추가
      "profileImage": profileImage, // ✅ 친구 요청 보낼 때 profileImage 추가
      "timestamp": FieldValue.serverTimestamp(),
    });

    print("✅ 친구 요청 전송 완료: $targetUserId");
  }



  /// ✅ 친구 목록 개수를 계산하고 Firestore에 `friendCount` 필드 업데이트
  Future<void> updateFriendCount(String userId) async {
    try {
      QuerySnapshot friendSnapshot = await _firestore
          .collection("users")
          .doc(userId)
          .collection("friends")
          .get();

      int friendCount = friendSnapshot.docs.length;

      await _firestore.collection("users").doc(userId).update({
        "friendCount": friendCount,
      });

      print("✅ Firestore에 friendCount 업데이트 완료: $friendCount명");
    } catch (e) {
      print("❌ Firestore에서 friendCount 업데이트 중 오류 발생: $e");
    }
  }

  /// ✅ Firestore에서 친구 목록을 실시간 감지 (`snapshots()`)
  Stream<List<Map<String, dynamic>>> listenToFriends() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]); // ✅ 로그인 안 되어 있으면 빈 값 반환
    }

    return _firestore
        .collection("users")
        .doc(userId)
        .collection("friends") // ✅ 친구 목록을 실시간 감지
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  /// ✅ Firestore에 유저 정보 업데이트
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore.collection("users").doc(userId).update(newData);
    } catch (e) {
      print("❌ Firestore에서 유저 정보를 업데이트하는 중 오류 발생: $e");
    }
  }

  /// ✅ 다트보드 목록 가져오기
  Future<List<String>> getDartboardList() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection("settings").doc("dartBoards").get();

      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc.data()!["boards"]);
      }
    } catch (e) {
      print("❌ Firestore에서 다트보드 목록을 불러오는 중 오류 발생: $e");
    }
    return ["다트라이브", "피닉스", "그란보드", "홈보드"]; // 기본값 반환
  }

  /// ✅ Firestore에서 최대 레이팅 가져오기 (앱 설정값)
  Future<int> getMaxRating() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection("settings").doc("rating").get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!["maxRating"] ?? 20; // 기본값 20
      }
    } catch (e) {
      print("❌ Firestore에서 최대 레이팅 값을 가져오는 중 오류 발생: $e");
    }
    return 20; // 기본값 반환
  }


  /// ✅ 로그아웃 시 Firestore 업데이트
  Future<void> updateUserLogout() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore.collection("users").doc(userId).update({
        "isOnline": false,
        "lastLogoutTime": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Firestore에서 로그아웃 정보 업데이트 중 오류 발생: $e");
    }
  }

  /// ✅ 차단된 유저 목록 가져오기
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore.collection("users").doc(userId).collection("blockedUsers").get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("❌ Firestore에서 차단된 유저 목록을 불러오는 중 오류 발생: $e");
      return [];
    }
  }

  /// ✅ 차단된 유저 목록을 실시간 감지 (Stream 반환)
  Stream<List<Map<String, dynamic>>> listenToBlockedUsers() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection("users")
        .doc(userId)
        .collection("blockedUsers")
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  /// ✅ 차단 해제 (Firestore에서 해당 차단 유저 삭제)
  Future<void> unblockUser(String blockedUserId) async {
    final userId = currentUserId;
    if (userId == null) {
      print("❌ 오류: 로그인되지 않은 상태에서 차단 해제 요청 발생");
      return;
    }

    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("blockedUsers")
          .doc(blockedUserId)
          .delete();
      print("✅ 차단 해제 완료: $blockedUserId");
    } catch (e) {
      print("❌ Firestore에서 차단 해제 중 오류 발생: $e");
    }
  }

  /// ✅ 친구 요청 목록을 실시간 감지 (Stream 반환)
  Stream<List<Map<String, dynamic>>> listenToFriendRequests() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection("users")
        .doc(userId)
        .collection("friendRequests")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "userId": doc.id, // ✅ 유저 ID 기본값 추가
          "nickname": data["nickname"] ?? "알 수 없는 사용자", // ✅ 닉네임 기본값 추가
          "profileImage": data["profileImage"] ?? "", // ✅ 프로필 이미지 기본값 추가
        };
      }).toList();
    });
  }

  /// ✅ 친구 요청 승인 (Firestore에 친구 추가 + friendCount 업데이트)
  Future<void> acceptFriendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // 🔹 친구 요청 삭제
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("friendRequests")
          .doc(friendId)
          .delete();

      // 🔹 서로 친구 목록에 추가
      await _firestore.collection("users").doc(userId).collection("friends").doc(friendId).set({
        "userId": friendId,
        "addedAt": FieldValue.serverTimestamp(),
      });

      await _firestore.collection("users").doc(friendId).collection("friends").doc(userId).set({
        "userId": userId,
        "addedAt": FieldValue.serverTimestamp(),
      });

      // 🔹 **friendCount 필드 업데이트** (존재하지 않으면 기본값 0)
      await _firestore.collection("users").doc(userId).update({
        "friendCount": FieldValue.increment(1), // ✅ 친구 수 증가
      });

      await _firestore.collection("users").doc(friendId).update({
        "friendCount": FieldValue.increment(1), // ✅ 상대방 친구 수 증가
      });

      print("✅ 친구 요청 승인 완료: $friendId");
    } catch (e) {
      print("❌ Firestore에서 친구 요청 승인 중 오류 발생: $e");
    }
  }

  /// ✅ 친구 요청 거절 (Firestore에서 요청 삭제)
  Future<void> declineFriendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("friendRequests")
          .doc(friendId)
          .delete();

      print("✅ 친구 요청 거절 완료: $friendId");
    } catch (e) {
      print("❌ Firestore에서 친구 요청 거절 중 오류 발생: $e");
    }
  }

  /// ✅ 친구 목록 불러오기
  Future<List<Map<String, dynamic>>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore.collection("users").doc(userId).collection("friends").get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("❌ Firestore에서 친구 목록을 불러오는 중 오류 발생: $e");
      return [];
    }
  }

  /// ✅ 친구 삭제 (Firestore에서 친구 제거 & `friendCount` 업데이트)
  Future<void> removeFriend(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // 친구 관계 삭제
      await _firestore.collection("users").doc(userId).collection("friends").doc(friendId).delete();
      await _firestore.collection("users").doc(friendId).collection("friends").doc(userId).delete();

      // ✅ 친구 수 업데이트
      await updateFriendCount(userId);
      await updateFriendCount(friendId);

      print("✅ 친구 삭제 완료: $friendId");
    } catch (e) {
      print("❌ Firestore에서 친구 삭제 중 오류 발생: $e");
    }
  }

  /// ✅ 닉네임 중복 검사
  Future<bool> isNicknameUnique(String nickname) async {
    try {
      QuerySnapshot result = await _firestore.collection("users").where("nickname", isEqualTo: nickname).limit(1).get();
      return result.docs.isEmpty;
    } catch (e) {
      print("❌ Firestore에서 닉네임 중복 검사 중 오류 발생: $e");
      return false;
    }
  }
}

