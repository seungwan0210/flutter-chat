import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOfflineMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineMode();
  }

  /// Firestore에서 현재 유저의 isOfflineMode 값을 가져옴
  Future<void> _loadOfflineMode() async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(currentUserId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isOfflineMode = userData["isOfflineMode"] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오프라인 모드 설정 로드 중 오류: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Firestore에 isOfflineMode 값을 업데이트
  Future<void> _updateOfflineMode(bool newValue) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      await _firestore.collection("users").doc(currentUserId).update({
        "isOfflineMode": newValue,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("설정이 저장되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오프라인 모드 설정 저장 중 오류: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "프로필 설정",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "오프라인 모드",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "오프라인 모드 활성화",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Switch(
                  value: _isOfflineMode,
                  onChanged: (newValue) {
                    setState(() {
                      _isOfflineMode = newValue;
                    });
                    _updateOfflineMode(newValue);
                  },
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "오프라인 모드를 활성화하면 다른 사용자가 나를 오프라인 상태로 보게 됩니다.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}