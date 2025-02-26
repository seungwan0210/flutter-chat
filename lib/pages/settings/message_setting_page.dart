import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class MessageSettingPage extends StatefulWidget {
  const MessageSettingPage({Key? key}) : super(key: key);

  @override
  _MessageSettingPageState createState() => _MessageSettingPageState();
}

class _MessageSettingPageState extends State<MessageSettingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedMessageSetting = "모든 사람"; // 기본값
  bool _isSaving = false;

  final List<String> _messageSettings = ["모든 사람", "친구만", "메시지 차단"];

  @override
  void initState() {
    super.initState();
    _loadMessageSetting();
  }

  /// Firestore에서 현재 유저의 메시지 설정 가져오기
  Future<void> _loadMessageSetting() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _selectedMessageSetting = userData["messageReceiveSetting"] ?? "모든 사람";
      });
    }
  }

  /// Firestore에 메시지 수신 설정 업데이트
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

      Navigator.pop(context); // ✅ 이전 페이지로 돌아가기
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
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.listenToUserData(), // ✅ 실시간 업데이트 적용!
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _selectedMessageSetting =
                snapshot.data?["messageReceiveSetting"] ?? "모든 사람";
          }

          return ListView.builder(
            itemCount: _messageSettings.length,
            itemBuilder: (context, index) {
              String setting = _messageSettings[index];
              return RadioListTile<String>(
                title: Text(setting),
                value: setting,
                groupValue: _selectedMessageSetting,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMessageSetting = value;
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
