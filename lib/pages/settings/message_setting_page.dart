import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class MessageSettingPage extends StatefulWidget {
  const MessageSettingPage({super.key});

  @override
  _MessageSettingPageState createState() => _MessageSettingPageState();
}

class _MessageSettingPageState extends State<MessageSettingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedMessageSetting = "모든 사람";
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  final List<String> _messageSettings = ["모든 사람", "친구만", "메시지 차단"];

  @override
  void initState() {
    super.initState();
    _loadMessageSetting();
  }

  /// Firestore에서 현재 유저의 메시지 설정 가져오기
  Future<void> _loadMessageSetting() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedMessageSetting = userData["messageReceiveSetting"] ?? "모든 사람";
          _isLoaded = true;
        });
      } else {
        setState(() {
          _errorMessage = "사용자 데이터를 불러올 수 없습니다.";
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "메시지 설정을 불러오는 중 오류가 발생했습니다: $e";
          _isLoaded = true;
        });
      }
    }
  }

  /// Firestore에 메시지 수신 설정 업데이트
  Future<void> _saveMessageSetting() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({
        "messageReceiveSetting": _selectedMessageSetting,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("메시지 수신 설정이 변경되었습니다.")),
        );
        Navigator.pop(context, _selectedMessageSetting);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "메시지 설정 저장 중 오류가 발생했습니다: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "메시지 수신 설정",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _errorMessage != null && !_isLoaded
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
                  : !_isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _messageSettings.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemBuilder: (context, index) {
                  String setting = _messageSettings[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<String>(
                      title: Text(
                        setting,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: setting,
                      groupValue: _selectedMessageSetting,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMessageSetting = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedMessageSetting == setting,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage != null && _isLoaded)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMessageSetting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                      : Text(
                    "저장하기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}