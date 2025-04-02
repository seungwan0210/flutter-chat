import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class MessageSettingPage extends StatefulWidget {
  const MessageSettingPage({super.key});

  @override
  _MessageSettingPageState createState() => _MessageSettingPageState();
}

class _MessageSettingPageState extends State<MessageSettingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger();
  String _selectedMessageSetting = "all"; // 기본값을 `all`로 변경
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  // 고정 키와 번역 매핑
  static const List<String> _messageSettingKeys = [
    "all", // `all_allowed`를 `all`로 변경
    "friendsOnly",
    "messageBlocked",
  ];

  Map<String, String> _getTranslatedSettings(BuildContext context) {
    return {
      "all": AppLocalizations.of(context)!.all_allowed,
      "friendsOnly": AppLocalizations.of(context)!.friendsOnly,
      "messageBlocked": AppLocalizations.of(context)!.messageBlocked,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadMessageSetting();
    _logger.i("MessageSettingPage initState called");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.i("MessageSettingPage didChangeDependencies called");
  }

  @override
  void dispose() {
    _logger.i("MessageSettingPage dispose called");
    super.dispose();
  }

  Future<void> _loadMessageSetting() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedMessageSetting = userData["messageSetting"] ?? "all"; // `messageReceiveSetting`을 `messageSetting`으로 변경
          _isLoaded = true;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorLoadingUserData;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingMessageSettings}: $e";
          _isLoaded = true;
        });
      }
      _logger.e("Error loading message settings: $e");
    }
  }

  Future<void> _saveMessageSetting() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({
        "messageSetting": _selectedMessageSetting, // `messageReceiveSetting`을 `messageSetting`으로 변경
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.messageSettingsSaved)),
        );
        Navigator.pop(context, _selectedMessageSetting);
      }
      _logger.i("Message setting saved: $_selectedMessageSetting");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
        });
      }
      _logger.e("Error saving message setting: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> translatedSettings = _getTranslatedSettings(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.messageSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _messageSettingKeys.length,
                itemBuilder: (context, index) {
                  String settingKey = _messageSettingKeys[index];
                  String settingDisplay = translatedSettings[settingKey] ?? settingKey;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<String>(
                      title: Text(
                        settingDisplay,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: settingKey,
                      groupValue: _selectedMessageSetting,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMessageSetting = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedMessageSetting == settingKey,
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
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMessageSetting,
                  icon: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    AppLocalizations.of(context)!.save,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaving ? Colors.grey : Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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