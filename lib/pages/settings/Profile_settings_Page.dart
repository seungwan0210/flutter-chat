import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 언어팩 임포트

class ProfileSettingsPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const ProfileSettingsPage({super.key, required this.onLocaleChange});

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
        SnackBar(content: Text("${AppLocalizations.of(context)!.errorLoadingOfflineMode}: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOfflineMode(bool newValue) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      await _firestore.collection("users").doc(currentUserId).update({
        "isOfflineMode": newValue,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.errorSavingOfflineMode}: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileSettings,
          style: const TextStyle(color: Colors.white),
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
            // 오프라인 모드 설정
            Text(
              AppLocalizations.of(context)!.offlineMode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.enableOfflineMode,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.offlineModeDescription,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
            const SizedBox(height: 24),
            // 언어 설정
            Text(
              AppLocalizations.of(context)!.languageSettings,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.languageSettingsDescription,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: AppLocalizations.supportedLocales.firstWhere(
                          (locale) =>
                      locale.languageCode == currentLocale.languageCode &&
                          (locale.countryCode == currentLocale.countryCode ||
                              (locale.countryCode == null && currentLocale.countryCode == '')),
                      orElse: () => AppLocalizations.supportedLocales.first,
                    ),
                    items: AppLocalizations.supportedLocales.map((locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          {
                            'ko': '한국어',
                            'en': 'English',
                            'ja': '日本語',
                            'zh': '中文 (简体)',
                            'zh_TW': '中文 (繁體)',
                          }[locale.toString()] ?? locale.toString(),
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      );
                    }).toList(),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        widget.onLocaleChange(newLocale);
                        setState(() {}); // UI 갱신 강제
                      }
                    },
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    style: const TextStyle(color: Colors.black54),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}