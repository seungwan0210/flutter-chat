import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class NicknameEditPage extends StatefulWidget {
  const NicknameEditPage({Key? key}) : super(key: key);

  @override
  _NicknameEditPageState createState() => _NicknameEditPageState();
}

class _NicknameEditPageState extends State<NicknameEditPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  /// Firestore에서 현재 닉네임 가져오기
  Future<void> _loadNickname() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null) {
      setState(() {
        _nicknameController.text = userData["nickname"] ?? "";
      });
    }
  }

  /// 닉네임 유효성 검사 (부적절한 단어 & 특수문자 제한)
  bool _isValidNickname(String nickname) {
    final invalidChars = RegExp(r"[^a-zA-Z0-9가-힣_]"); // 한글, 영문, 숫자, 밑줄(_) 허용
    final bannedWords = ["admin", "운영자", "관리자", "fuck", "shit", "욕설"]; // 예제

    if (nickname.length < 2 || nickname.length > 12) return false; // 글자 수 제한
    if (invalidChars.hasMatch(nickname)) return false; // 특수문자 포함 여부
    if (bannedWords.any((word) => nickname.toLowerCase().contains(word))) return false; // 금지 단어 포함 여부

    return true;
  }

  /// Firestore에서 닉네임 중복 체크
  Future<bool> _isNicknameAvailable(String nickname) async {
    return await _firestoreService.isNicknameUnique(nickname);
  }

  /// 닉네임 저장 기능
  Future<void> _saveNickname() async {
    String newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임을 입력해주세요.")),
      );
      return;
    }

    if (!_isValidNickname(newNickname)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임은 2~12자, 한글/영문/숫자/밑줄(_)만 사용할 수 있습니다.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool isAvailable = await _isNicknameAvailable(newNickname);
    if (!isAvailable) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미 사용 중인 닉네임입니다.")),
      );
      return;
    }

    await _firestoreService.updateUserData({"nickname": newNickname});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("닉네임이 변경되었습니다.")),
    );

    Navigator.pop(context, newNickname); // ✅ 변경된 닉네임을 반환하여 업데이트 유도
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("닉네임 변경"),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNickname,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: "새 닉네임",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNickname,
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }
}
