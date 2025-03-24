import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Play_summary_detail_Page.dart';

class PlaySummaryHistoryPage extends StatefulWidget {
  final DateTime selectedDate;

  const PlaySummaryHistoryPage({super.key, required this.selectedDate});

  @override
  State<PlaySummaryHistoryPage> createState() => _PlaySummaryHistoryPageState();
}

class _PlaySummaryHistoryPageState extends State<PlaySummaryHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Firestore에서 선택된 날짜의 플레이 요약 로드
  Future<void> _loadSummary() async {
    String userId = _auth.currentUser!.uid;
    String date = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
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
  }

  /// Firestore에서 선택된 날짜의 플레이 요약 삭제
  Future<void> _deleteSummary() async {
    String userId = _auth.currentUser!.uid;
    String date = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("daily_play_summary")
          .doc(date)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("플레이 요약이 삭제되었습니다.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("삭제 중 오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${DateFormat('yyyy년 M월 d일').format(widget.selectedDate)} 요약",
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
          child: _summary == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "플레이 요약",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSummaryItem("상태", _summary!['emoji'] ?? "😊"),
                          _buildSummaryItem("플레이한 보드", _summary!['board'] ?? "없음"),
                          _buildSummaryItem("경기 수", _summary!['games_played']?.toString() ?? "없음"),
                          _buildSummaryItem("가장 잘된 점", _summary!['best_performance'] ?? "없음"),
                          _buildSummaryItem("개선할 점", _summary!['improvements'] ?? "없음"),
                          _buildSummaryItem("한 줄 메모", _summary!['memo'] ?? "없음"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton("수정", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaySummaryDetailPage(selectedDate: widget.selectedDate),
                      ),
                    ).then((_) {
                      Navigator.pop(context); // 수정 후 이전 페이지로 돌아감
                    });
                  }),
                  const SizedBox(width: 12),
                  _buildButton("삭제", _deleteSummary, color: Theme.of(context).colorScheme.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 요약 정보 항목
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
        onPressed: onPressed,
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
}