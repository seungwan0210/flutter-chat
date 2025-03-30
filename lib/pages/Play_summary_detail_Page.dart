import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'package:intl/intl.dart' as intl;

class PlaySummaryDetailPage extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const PlaySummaryDetailPage({super.key, required this.selectedDate, required this.onLocaleChange});

  @override
  State<PlaySummaryDetailPage> createState() => _PlaySummaryDetailPageState();
}

class _PlaySummaryDetailPageState extends State<PlaySummaryDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _gamesPlayedController = TextEditingController();
  final TextEditingController _bestPerformanceController = TextEditingController();
  final TextEditingController _improvementController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String _selectedBoard = "다트라이브";
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedEmoji = "😊"; // 기본 이모티콘 (최상)

  final Map<String, String> _emojiOptions = {
    "😊": "최상",
    "🙂": "중상",
    "😐": "보통",
    "😕": "중하",
    "😢": "최하",
  };

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _gamesPlayedController.dispose();
    _bestPerformanceController.dispose();
    _improvementController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      String userId = _auth.currentUser!.uid;
      String date = intl.DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("daily_play_summary")
          .doc(date)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _selectedBoard = data['board'] ?? "다트라이브";
          _gamesPlayedController.text = data['games_played']?.toString() ?? "";
          _bestPerformanceController.text = data['best_performance'] ?? "";
          _improvementController.text = data['improvements'] ?? "";
          _memoController.text = data['memo'] ?? "";
          _selectedEmoji = data['emoji'] ?? "😊";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "${AppLocalizations.of(context)!.errorLoadingStats}: $e";
      });
    }
  }

  Future<void> _savePlaySummary() async {
    if (_gamesPlayedController.text.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterGamesPlayed);
      return;
    }
    if (_bestPerformanceController.text.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterBestPerformance);
      return;
    }
    if (_improvementController.text.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.enterImprovement);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String userId = _auth.currentUser!.uid;
    String date = intl.DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    DocumentReference summaryRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("daily_play_summary")
        .doc(date);

    try {
      DocumentSnapshot snapshot = await summaryRef.get();

      Map<String, dynamic> newData = {
        "date": date,
        "board": _selectedBoard,
        "games_played": int.parse(_gamesPlayedController.text),
        "best_performance": _bestPerformanceController.text,
        "improvements": _improvementController.text,
        "memo": _memoController.text,
        "emoji": _selectedEmoji,
      };

      if (snapshot.exists) {
        await summaryRef.set(newData, SetOptions(merge: true));
      } else {
        await summaryRef.set(newData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.playSummarySaved)),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = "${AppLocalizations.of(context)!.saveFailed}: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${getFormattedDate(context, widget.selectedDate)} ${AppLocalizations.of(context)!.summary}",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.writePlaySummary,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                _buildEmojiSelector(),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                _buildDropdown(),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                _buildTextField(_gamesPlayedController, AppLocalizations.of(context)!.gamesPlayed, TextInputType.number),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                _buildTextField(_bestPerformanceController, AppLocalizations.of(context)!.bestPerformance),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                _buildTextField(_improvementController, AppLocalizations.of(context)!.improvement),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                _buildTextField(_memoController, AppLocalizations.of(context)!.memo),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildButton(
                  _isLoading ? AppLocalizations.of(context)!.loading : AppLocalizations.of(context)!.save,
                  _isLoading ? () {} : _savePlaySummary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.playStatusToday,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _emojiOptions.entries.map((entry) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmoji = entry.key;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 20,
                      color: _selectedEmoji == entry.key ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    translateEmoji(context, entry.value),
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedEmoji == entry.key ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBoard,
      items: ["다트라이브", "피닉스", "그란보드", "홈보드"].map((board) {
        return DropdownMenuItem(value: board, child: Text(translate(context, board)));
      }).toList(),
      onChanged: _isLoading ? null : (value) => setState(() => _selectedBoard = value!),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.playedBoard,
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      enabled: !_isLoading, // 로딩 중에는 비활성화
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  String translateEmoji(BuildContext context, String key) {
    switch (key) {
      case "최상":
        return AppLocalizations.of(context)!.excellent;
      case "중상":
        return AppLocalizations.of(context)!.good;
      case "보통":
        return AppLocalizations.of(context)!.average;
      case "중하":
        return AppLocalizations.of(context)!.belowAverage;
      case "최하":
        return AppLocalizations.of(context)!.poor;
      default:
        return key;
    }
  }

  String translate(BuildContext context, String key) {
    switch (key) {
      case "다트라이브":
        return AppLocalizations.of(context)!.dartlive;
      case "피닉스":
        return AppLocalizations.of(context)!.phoenix;
      case "그란보드":
        return AppLocalizations.of(context)!.granboard;
      case "홈보드":
        return AppLocalizations.of(context)!.homeboard;
      default:
        return key;
    }
  }

  String getFormattedDate(BuildContext context, DateTime date) {
    var locale = Localizations.localeOf(context).toString();
    return intl.DateFormat.yMMMMd(locale).format(date); // 로케일에 맞는 날짜 형식
  }
}