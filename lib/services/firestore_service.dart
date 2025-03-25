import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart'; // Logger 추가
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger(); // Logger 인스턴스 추가

  FirebaseFirestore get firestore => _firestore;
  String? get currentUserId => _auth.currentUser?.uid;

  String sanitizeProfileImage(String? profileImage) {
    if (profileImage == null || profileImage.contains('via.placeholder.com') || Uri.tryParse(profileImage)?.hasAbsolutePath != true) {
      return "";
    }
    return profileImage;
  }

  List<Map<String, dynamic>> sanitizeProfileImages(List<dynamic>? profileImages) {
    if (profileImages == null || profileImages.isEmpty) return [];
    return profileImages
        .map((item) {
      if (item is Map<String, dynamic> && item.containsKey('url')) {
        String url = sanitizeProfileImage(item['url'] as String?);
        if (url.isNotEmpty) {
          return {
            'url': url,
            'timestamp': item['timestamp'] ?? '',
          };
        }
      }
      return null;
    })
        .where((item) => item != null && item['url'] != null && item['url'].isNotEmpty)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  String getFirstProfileImage(List<Map<String, dynamic>> profileImages) {
    return profileImages.isNotEmpty ? profileImages.first['url'] : "";
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      String userId = _auth.currentUser!.uid;
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('users/$userId/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      DocumentReference userRef = _firestore.collection("users").doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      List<Map<String, dynamic>> profileImages = userData != null && userData.containsKey('profileImages')
          ? List<Map<String, dynamic>>.from(userData['profileImages'])
          : [];

      String timestamp = DateTime.now().toIso8601String();
      profileImages.add({
        'url': downloadUrl,
        'timestamp': timestamp,
      });

      await userRef.update({
        'profileImages': profileImages,
        'mainProfileImage': downloadUrl,
      });

      return {'url': downloadUrl, 'timestamp': timestamp};
    } catch (e) {
      _logger.e("❌ 프로필 이미지 업로드 중 오류 발생: $e");
      throw Exception("프로필 이미지 업로드 실패: $e");
    }
  }

  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentReference userRef = _firestore.collection("users").doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null || !userData.containsKey('profileImages')) {
        throw Exception("프로필 이미지가 존재하지 않습니다.");
      }

      List<Map<String, dynamic>> profileImages = List<Map<String, dynamic>>.from(userData['profileImages']);
      profileImages.removeWhere((item) => item['url'] == imageUrl);

      String? mainProfileImage = userData['mainProfileImage'];
      if (mainProfileImage == imageUrl) {
        mainProfileImage = profileImages.isNotEmpty ? profileImages.last['url'] : null;
      }

      await _storage.refFromURL(imageUrl).delete();

      await userRef.update({
        'profileImages': profileImages,
        'mainProfileImage': mainProfileImage,
      });
    } catch (e) {
      _logger.e("❌ 프로필 이미지 삭제 중 오류 발생: $e");
      throw Exception("프로필 이미지 삭제 실패: $e");
    }
  }

  Future<void> migrateProfileImagesToNewFormat() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection("users").get();
      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('profileImages')) {
          List<dynamic> oldProfileImages = userData['profileImages'];
          if (oldProfileImages.isNotEmpty && oldProfileImages.first is String) {
            List<Map<String, dynamic>> newProfileImages = oldProfileImages.map((url) {
              return {
                'url': url,
                'timestamp': DateTime.now().toIso8601String(),
              };
            }).toList();
            await userDoc.reference.update({
              'profileImages': newProfileImages,
              'mainProfileImage': newProfileImages.last['url'],
            });
            _logger.i("✅ 사용자 ${userDoc.id}의 프로필 이미지 마이그레이션 완료");
          }
        }
      }
      _logger.i("✅ 모든 사용자 프로필 이미지 마이그레이션 완료");
    } catch (e) {
      _logger.e("❌ Firestore 데이터 마이그레이션 중 오류 발생: $e");
      throw Exception("Firestore 데이터 마이그레이션 실패: $e");
    }
  }

  Future<void> setMainProfileImage(String? imageUrl) async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentReference userRef = _firestore.collection("users").doc(userId);
      await userRef.update({
        'mainProfileImage': imageUrl,
      });
    } catch (e) {
      _logger.e("❌ 대표 이미지 설정 중 오류 발생: $e");
      throw Exception("대표 이미지 설정 실패: $e");
    }
  }

  Future<void> setOfflineMode(bool isOfflineMode) async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentReference userRef = _firestore.collection("users").doc(userId);
      await userRef.update({
        'isOfflineMode': isOfflineMode,
      });
      if (isOfflineMode) {
        await userRef.update({
          'status': "offline",
        });
      }
    } catch (e) {
      _logger.e("❌ 오프라인 모드 설정 중 오류 발생: $e");
      throw Exception("오프라인 모드 설정 실패: $e");
    }
  }

  Future<void> updateUserStatus(bool isOnline) async {
    try {
      String userId = _auth.currentUser!.uid;
      _logger.i("Updating user status for UID: $userId to ${isOnline ? 'online' : 'offline'}");
      DocumentReference userRef = _firestore.collection("users").doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        _logger.w("User data not found for UID: $userId");
        throw Exception("유저 데이터를 찾을 수 없습니다.");
      }

      bool isOfflineMode = userData["isOfflineMode"] ?? false;
      _logger.i("isOfflineMode: $isOfflineMode");

      if (isOfflineMode) {
        await userRef.update({
          'status': "offline",
        });
        _logger.i("User status set to offline due to offline mode");
      } else {
        await userRef.update({
          'status': isOnline ? "online" : "offline",
        });
        _logger.i("User status updated to ${isOnline ? 'online' : 'offline'}");
      }
    } catch (e) {
      _logger.e("❌ 유저 상태 업데이트 중 오류 발생: $e");
      throw Exception("유저 상태 업데이트 실패: $e");
    }
  }

  Stream<bool> listenToBlockedStatus(String userId) {
    String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<Map<String, dynamic>>> listenToBlockedUsers() {
    String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("blockedUsers")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          "blockedUserId": doc.id,
          "nickname": data["nickname"] ?? "알 수 없는 사용자",
          "profileImages": data["profileImages"] ?? [],
          "mainProfileImage": data["mainProfileImage"] ?? "",
          "status": data["status"] ?? "offline",
        };
      }).toList();
    });
  }

  Future<void> toggleBlockUser(String userId, String nickname, List<Map<String, dynamic>> profileImages) async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference blockRef = _firestore.collection("users").doc(currentUserId).collection("blockedUsers").doc(userId);
    DocumentSnapshot blockDoc = await blockRef.get();

    DocumentReference userRef = _firestore.collection("users").doc(userId);
    DocumentSnapshot userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw Exception("유저 정보를 찾을 수 없습니다.");
    }
    var userData = userDoc.data() as Map<String, dynamic>;

    if (blockDoc.exists) {
      await blockRef.delete();
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          int currentBlockedByCount = snapshot["blockedByCount"] ?? 0;
          int newBlockedByCount = currentBlockedByCount > 0 ? currentBlockedByCount - 1 : 0;
          transaction.update(userRef, {
            "blockedByCount": newBlockedByCount,
          });
        }
      });
    } else {
      await blockRef.set({
        "blockedUserId": userId,
        "nickname": nickname,
        "profileImages": profileImages,
        "mainProfileImage": profileImages.isNotEmpty ? profileImages.last['url'] : "",
        "status": userData["status"] ?? "offline",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          int currentBlockedByCount = snapshot["blockedByCount"] ?? 0;
          int newBlockedByCount = currentBlockedByCount + 1;

          transaction.update(userRef, {
            "blockedByCount": newBlockedByCount,
          });

          if (newBlockedByCount >= 10) {
            transaction.update(userRef, {
              "isActive": false,
            });
          }
        } else {
          transaction.set(userRef, {
            "blockedByCount": 1,
            "isActive": true,
          }, SetOptions(merge: true));
        }
      });
    }
  }

  Future<void> unblockUser(String userId) async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentReference blockRef = _firestore.collection("users").doc(currentUserId).collection("blockedUsers").doc(userId);
    DocumentReference userRef = _firestore.collection("users").doc(userId);

    await blockRef.delete();

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (snapshot.exists) {
        int currentBlockedByCount = snapshot["blockedByCount"] ?? 0;
        int newBlockedByCount = currentBlockedByCount > 0 ? currentBlockedByCount - 1 : 0;
        transaction.update(userRef, {
          "blockedByCount": newBlockedByCount,
        });
      }
    });
  }

  Future<bool> isUserActive(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      bool isActive = userDoc.exists && (userDoc["isActive"] ?? true);
      _logger.i("isUserActive for UID: $userId, result: $isActive");
      return isActive;
    } catch (e) {
      _logger.e("Error in isUserActive: $e");
      return true; // 기본값 true 반환
    }
  }

  Future<void> incrementProfileViews(String userId) async {
    String? currentUserId = this.currentUserId;
    if (currentUserId == null || currentUserId == userId) return;

    DocumentReference userRef = _firestore.collection("users").doc(userId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
      if (userData == null) return;

      int totalViews = userData["totalViews"] ?? 0;
      int todayViews = userData["todayViews"] ?? 0;
      DateTime lastViewDate = userData["lastViewDate"]?.toDate() ?? DateTime.now();
      DateTime now = DateTime.now();

      if (now.difference(lastViewDate).inDays >= 1) {
        todayViews = 1;
      } else {
        todayViews += 1;
      }

      transaction.update(userRef, {
        "totalViews": totalViews + 1,
        "todayViews": todayViews,
        "lastViewDate": now,
      });
    });
  }

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

  Future<Map<String, dynamic>?> getUserData({String? userId}) async {
    userId ??= currentUserId;
    if (userId == null) {
      _logger.w("❌ 오류: 로그인되지 않은 상태에서 유저 정보를 요청했습니다.");
      return null;
    }
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) return null;

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      userData["friendCount"] = userData.containsKey("friendCount") ? userData["friendCount"] : 0;
      userData["rating"] = userData.containsKey("rating") ? userData["rating"] : 0;
      userData["profileImages"] = userData.containsKey("profileImages") ? userData["profileImages"] : [];
      userData["mainProfileImage"] = userData.containsKey("mainProfileImage")
          ? userData["mainProfileImage"]
          : (userData["profileImages"].isNotEmpty ? userData["profileImages"].last['url'] : null);
      return userData;
    } catch (e) {
      _logger.e("❌ Firestore에서 유저 정보를 불러오는 중 오류 발생: $e");
      return null;
    }
  }

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

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    if (userData == null) return;

    String nickname = userData["nickname"] ?? "알 수 없는 사용자";
    List<Map<String, dynamic>> profileImages = sanitizeProfileImages(userData["profileImages"]);
    String firstImage = getFirstProfileImage(profileImages);

    DocumentReference requestRef = _firestore
        .collection("users")
        .doc(targetUserId)
        .collection("friendRequests")
        .doc(currentUserId);

    await requestRef.set({
      "fromUserId": currentUserId,
      "nickname": nickname,
      "profileImages": profileImages,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFriendCount(String userId) async {
    try {
      QuerySnapshot friendSnapshot = await _firestore.collection("users").doc(userId).collection("friends").get();
      int friendCount = friendSnapshot.docs.length;
      await _firestore.collection("users").doc(userId).update({"friendCount": friendCount});
    } catch (e) {
      _logger.e("❌ Firestore에서 friendCount 업데이트 중 오류 발생: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> listenToFriends() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection("users")
        .doc(userId)
        .collection("friends")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore.collection("users").doc(userId).update(newData);
    } catch (e) {
      _logger.e("❌ Firestore에서 유저 정보를 업데이트하는 중 오류 발생: $e");
    }
  }

  Future<List<String>> getDartboardList() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection("settings").doc("dartBoards").get();
      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc.data()!["boards"]);
      }
    } catch (e) {
      _logger.e("❌ Firestore에서 다트보드 목록을 불러오는 중 오류 발생: $e");
    }
    return ["다트라이브", "피닉스", "그란보드", "홈보드"];
  }

  Future<int> getMaxRating() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection("settings").doc("rating").get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!["maxRating"] ?? 20;
      }
    } catch (e) {
      _logger.e("❌ Firestore에서 최대 레이팅 값을 가져오는 중 오류 발생: $e");
    }
    return 20;
  }

  Future<void> updateUserLogout() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore.collection("users").doc(userId).update({
        "isOnline": false,
        "lastLogoutTime": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e("❌ Firestore에서 로그아웃 정보 업데이트 중 오류 발생: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore.collection("users").doc(userId).collection("blockedUsers").get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.e("❌ Firestore에서 차단된 유저 목록을 불러오는 중 오류 발생: $e");
      return [];
    }
  }

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
        .map((snapshot) => snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        "userId": doc.id,
        "nickname": data["nickname"] ?? "알 수 없는 사용자",
        "profileImages": data["profileImages"] ?? [],
      };
    }).toList());
  }

  Future<void> acceptFriendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection("users").doc(userId).collection("friendRequests").doc(friendId).delete();
      await _firestore.collection("users").doc(userId).collection("friends").doc(friendId).set({
        "userId": friendId,
        "addedAt": FieldValue.serverTimestamp(),
      });
      await _firestore.collection("users").doc(friendId).collection("friends").doc(userId).set({
        "userId": userId,
        "addedAt": FieldValue.serverTimestamp(),
      });
      await _firestore.collection("users").doc(userId).update({"friendCount": FieldValue.increment(1)});
      await _firestore.collection("users").doc(friendId).update({"friendCount": FieldValue.increment(1)});
    } catch (e) {
      _logger.e("❌ Firestore에서 친구 요청 승인 중 오류 발생: $e");
    }
  }

  Future<void> declineFriendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection("users").doc(userId).collection("friendRequests").doc(friendId).delete();
    } catch (e) {
      _logger.e("❌ Firestore에서 친구 요청 거절 중 오류 발생: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore.collection("users").doc(userId).collection("friends").get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.e("❌ Firestore에서 친구 목록을 불러오는 중 오류 발생: $e");
      return [];
    }
  }

  Future<void> removeFriend(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection("users").doc(userId).collection("friends").doc(friendId).delete();
      await _firestore.collection("users").doc(friendId).collection("friends").doc(userId).delete();
      await updateFriendCount(userId);
      await updateFriendCount(friendId);
    } catch (e) {
      _logger.e("❌ Firestore에서 친구 삭제 중 오류 발생: $e");
    }
  }

  Future<bool> isNicknameUnique(String nickname) async {
    try {
      QuerySnapshot result = await _firestore.collection("users").where("nickname", isEqualTo: nickname).limit(1).get();
      return result.docs.isEmpty;
    } catch (e) {
      _logger.e("❌ Firestore에서 닉네임 중복 검사 중 오류 발생: $e");
      return false;
    }
  }
}