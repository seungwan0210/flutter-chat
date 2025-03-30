import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'package:intl/intl.dart' as intl;
import 'play_summary_detail_page.dart';

class PlaySummaryHistoryPage extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const PlaySummaryHistoryPage({super.key, required this.selectedDate, required this.onLocaleChange});

  @override
  State<PlaySummaryHistoryPage> createState() => _PlaySummaryHistoryPageState();
}

class _PlaySummaryHistoryPageState extends State<PlaySummaryHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Firestore에서 선택된 날짜의 플레이 요약 로드
  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
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
        setState(() {
          _summary = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.errorLoadingStats}: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Firestore에서 선택된 날짜의 플레이 요약 삭제
  Future<void> _deleteSummary() async {
    setState(() => _isLoading = true);
    String userId = _auth.currentUser!.uid;
    String date = intl.DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("daily_play_summary")
          .doc(date)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.playSummaryDeleted)),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.deleteFailed}: $e")),
      );
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
              ? Center(child: Text(AppLocalizations.of(context)!.noData))
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.todayPlaySummary,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryItem(AppLocalizations.of(context)!.status, _summary!['emoji'] ?? "😊"),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                _buildSummaryItem(AppLocalizations.of(context)!.playedBoard, _summary!['board'] ?? AppLocalizations.of(context)!.none),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                _buildSummaryItem(AppLocalizations.of(context)!.gamesPlayed, _summary!['games_played']?.toString() ?? AppLocalizations.of(context)!.none),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                _buildSummaryItem(AppLocalizations.of(context)!.bestPerformance, _summary!['best_performance'] ?? AppLocalizations.of(context)!.none),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                _buildSummaryItem(AppLocalizations.of(context)!.improvement, _summary!['improvements'] ?? AppLocalizations.of(context)!.none),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                _buildSummaryItem(AppLocalizations.of(context)!.memo, _summary!['memo'] ?? AppLocalizations.of(context)!.none),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(AppLocalizations.of(context)!.edit, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaySummaryDetailPage(
                            selectedDate: widget.selectedDate,
                            onLocaleChange: widget.onLocaleChange,
                          ),
                        ),
                      ).then((_) {
                        Navigator.pop(context); // 수정 후 이전 페이지로 돌아감
                      });
                    }),
                    const SizedBox(width: 12),
                    _buildButton(AppLocalizations.of(context)!.delete, _deleteSummary, color: Theme.of(context).colorScheme.error),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
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

  String getFormattedDate(BuildContext context, DateTime date) {
    var locale = Localizations.localeOf(context).toString();
    return intl.DateFormat.yMMMMd(locale).format(date); // 로케일에 맞는 날짜 형식
  }
}