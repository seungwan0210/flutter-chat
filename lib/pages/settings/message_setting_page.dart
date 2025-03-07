import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class MessageSettingPage extends StatefulWidget {
  const MessageSettingPage({super.key});

  @override
  _MessageSettingPageState createState() => _MessageSettingPageState();
}

class _MessageSettingPageState extends State<MessageSettingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedMessageSetting = "모든 사람"; // 기본값
  bool _isSaving = false;
  bool _isLoaded = false; // ✅ Firestore 데이터가 로드되었는지 체크

  final List<String> _messageSettings = ["모든 사람", "친구만", "메시지 차단"];

  @override
  void initState() {
    super.initState();
    _loadMessageSetting();
  }

  /// ✅ Firestore에서 현재 유저의 메시지 설정 가져오기
  Future<void> _loadMessageSetting() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _selectedMessageSetting = userData["messageReceiveSetting"] ?? "모든 사람";
        _isLoaded = true; // ✅ 데이터 로드 완료
      });
    }
  }

  /// ✅ Firestore에 메시지 수신 설정 업데이트
  Future<void> _saveMessageSetting() async {
    setState(() => _isSaving = true);

    await _firestoreService.updateUserData({
      "messageReceiveSetting": _selectedMessageSetting,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("메시지 수신 설정이 변경되었습니다.")),
      );
      Navigator.pop(context, _selectedMessageSetting); // ✅ 변경된 값을 반환하며 이전 페이지로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("메시지 수신 설정"),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveMessageSetting, // ✅ 중복 클릭 방지
          ),
        ],
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator()) // ✅ Firestore 데이터 로딩 중
          : ListView.builder(
        itemCount: _messageSettings.length,
        itemBuilder: (context, index) {
          String setting = _messageSettings[index];
          return RadioListTile<String>(
            title: Text(setting),
            value: setting,
            groupValue: _selectedMessageSetting, // ✅ Firestore 값과 동기화된 값 사용
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMessageSetting = value;
                });
              }
            },
          );
        },
      ),
    );
  }
}
