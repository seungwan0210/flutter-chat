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
  String _selectedMessageSetting = "";
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  final List<String> _messageSettings = [];

  @override
  void initState() {
    super.initState();
    _loadMessageSetting();
    _logger.i("MessageSettingPage initState called");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeMessageSettings();
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
          _selectedMessageSetting = userData["messageReceiveSetting"] ?? AppLocalizations.of(context)!.all_allowed;
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

  void _initializeMessageSettings() {
    _messageSettings.clear();
    _messageSettings.addAll([
      AppLocalizations.of(context)!.all_allowed,
      AppLocalizations.of(context)!.friendsOnly,
      AppLocalizations.of(context)!.messageBlocked,
    ]);
    // 로케일 변경 시 _selectedMessageSetting이 유효한지 확인
    if (!_messageSettings.contains(_selectedMessageSetting)) {
      setState(() {
        _selectedMessageSetting = _messageSettings[0]; // 기본값으로 설정
      });
    }
  }

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
                itemCount: _messageSettings.length,
                itemBuilder: (context, index) {
                  String setting = _messageSettings[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
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
                    backgroundColor: Theme.of(context).primaryColor,
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