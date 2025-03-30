import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class NicknameEditPage extends StatefulWidget {
  const NicknameEditPage({super.key});

  @override
  _NicknameEditPageState createState() => _NicknameEditPageState();
}

class _NicknameEditPageState extends State<NicknameEditPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nicknameController = TextEditingController();
  final Logger _logger = Logger();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _logger.i("NicknameEditPage initState called");
  }

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
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingNickname}: $e";
        });
      }
      _logger.e("Error loading nickname: $e");
    }
  }

  bool _isValidNickname(String nickname) {
    final invalidChars = RegExp(r"[^a-zA-Z0-9가-힣_]");
    final bannedWords = ["admin", "운영자", "관리자", "fuck", "shit", "욕설"];
    return nickname.trim().length >= 2 &&
        nickname.trim().length <= 12 &&
        !invalidChars.hasMatch(nickname) &&
        !bannedWords.any((word) => nickname.toLowerCase().contains(word));
  }

  Future<bool> _isNicknameAvailable(String nickname) async {
    try {
      return await _firestoreService.isNicknameUnique(nickname);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.errorCheckingNickname}: $e")),
        );
      }
      _logger.e("Error checking nickname availability: $e");
      return false;
    }
  }

  Future<void> _saveNickname() async {
    String newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterNickname);
      return;
    }

    if (!_isValidNickname(newNickname)) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.invalidNicknameFormat);
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
        _errorMessage = AppLocalizations.of(context)!.nicknameTaken;
      });
      return;
    }

    try {
      await _firestoreService.updateUserData({"nickname": newNickname});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nicknameSaved)),
        );
        _nicknameController.clear();
        Navigator.pop(context, newNickname);
      }
      _logger.i("Nickname saved: $newNickname");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
        });
      }
      _logger.e("Error saving nickname: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _validateNickname(String value) {
    if (value.isNotEmpty && !_isValidNickname(value)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.invalidNicknameFormat;
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
          AppLocalizations.of(context)!.nicknameSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nicknameController,
                    maxLength: 12,
                    onChanged: _validateNickname,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.newNickname,
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
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveNickname,
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