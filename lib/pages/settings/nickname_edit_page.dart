import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class NicknameEditPage extends StatefulWidget {
  const NicknameEditPage({super.key});

  @override
  _NicknameEditPageState createState() => _NicknameEditPageState();
}

class _NicknameEditPageState extends State<NicknameEditPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  /// Firestore에서 현재 닉네임 가져오기
  Future<void> _loadNickname() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _nicknameController.text = userData["nickname"] ?? "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "닉네임을 불러오는 중 오류가 발생했습니다: $e";
        });
      }
    }
  }

  /// 닉네임 유효성 검사 (실시간 반영)
  bool _isValidNickname(String nickname) {
    final invalidChars = RegExp(r"[^a-zA-Z0-9가-힣_]"); // 한글, 영문, 숫자, 밑줄(_) 허용
    final bannedWords = ["admin", "운영자", "관리자", "fuck", "shit", "욕설"]; // 금지어 예제

    if (nickname.trim().length < 2 || nickname.trim().length > 12) return false;
    if (invalidChars.hasMatch(nickname)) return false;
    if (bannedWords.any((word) => nickname.toLowerCase().contains(word))) return false;

    return true;
  }

  /// Firestore에서 닉네임 중복 체크
  Future<bool> _isNicknameAvailable(String nickname) async {
    try {
      return await _firestoreService.isNicknameUnique(nickname);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("닉네임 중복 확인 중 오류 발생: $e")),
        );
      }
      return false;
    }
  }

  /// 닉네임 저장 기능
  Future<void> _saveNickname() async {
    String newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      setState(() => _errorMessage = "닉네임을 입력해주세요!");
      return;
    }

    if (!_isValidNickname(newNickname)) {
      setState(() => _errorMessage = "닉네임은 2~12자, 한글/영문/숫자/밑줄(_)만 사용할 수 있습니다.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    bool isAvailable = await _isNicknameAvailable(newNickname);
    if (!isAvailable) {
      setState(() {
        _isSaving = false;
        _errorMessage = "이미 사용 중인 닉네임입니다.";
      });
      return;
    }

    try {
      await _firestoreService.updateUserData({"nickname": newNickname});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("닉네임이 변경되었습니다.")),
        );
        _nicknameController.clear();
        Navigator.pop(context, newNickname);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "닉네임 저장 중 오류가 발생했습니다: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 입력 중 실시간 유효성 검사
  void _validateNickname(String value) {
    if (value.isNotEmpty && !_isValidNickname(value)) {
      setState(() {
        _errorMessage = "닉네임은 2~12자, 한글/영문/숫자/밑줄(_)만 사용할 수 있습니다.";
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "닉네임 변경",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          _isSaving
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
          )
              : IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: _isSaving ? null : _saveNickname,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              TextField(
                controller: _nicknameController,
                maxLength: 12,
                onChanged: _validateNickname, // 실시간 유효성 검사
                decoration: InputDecoration(
                  labelText: "새 닉네임",
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  errorText: _errorMessage,
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveNickname,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Theme.of(context).disabledColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "저장",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}