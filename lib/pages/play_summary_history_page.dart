import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'play_summary_history_page.dart';

class PlaySummaryHistoryPage extends StatefulWidget {
  const PlaySummaryHistoryPage({super.key});

  @override
  State<PlaySummaryHistoryPage> createState() => _PlaySummaryHistoryPageState();
}

class _PlaySummaryHistoryPageState extends State<PlaySummaryHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "내 플레이 요약 기록",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // 테마 기반 배경
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(_auth.currentUser!.uid)
                  .collection("daily_play_summary")
                  .orderBy("date", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "기록을 불러오는 중 오류가 발생했습니다.",
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                var summaries = snapshot.data!.docs;

                if (summaries.isEmpty) {
                  return Center(
                    child: Text(
                      "아직 저장된 기록이 없습니다!",
                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    var summary = summaries[index].data() as Map<String, dynamic>? ?? {};
                    String date = summary["date"] ?? "날짜 없음";
                    String board = summary["board"] ?? "보드 없음";
                    int gamesPlayed = summary["games_played"] ?? 0;
                    String memo = summary["memo"] ?? "메모 없음";

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          "$date - $board",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          "경기 수: $gamesPlayed | 메모: $memo",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).primaryColor,
                        ),
                        onTap: () => _showSummaryDetail(summary, summaries[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 다이얼로그 - 스크롤 추가 & 섹션 스타일 업데이트
  void _showSummaryDetail(Map<String, dynamic> summary, String summaryId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${summary["date"] ?? "날짜 없음"} - ${summary["board"] ?? "보드 없음"}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoSection("경기 수", (summary["games_played"] ?? 0).toString()),
                        _infoSection("오늘 가장 잘된 점", summary["best_performance"] ?? "없음"),
                        _infoSection("오늘 개선할 점", summary["improvements"] ?? "없음"),
                        _infoSection("메모", summary["memo"] ?? "없음"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "닫기",
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _deleteSummary(summaryId),
                      child: Text(
                        "삭제",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 데이터 삭제 기능
  Future<void> _deleteSummary(String summaryId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .collection("daily_play_summary")
          .doc(summaryId)
          .delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("기록이 삭제되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("삭제 중 오류가 발생했습니다: $e")),
      );
    }
  }

  /// 정보 섹션 스타일 개선
  Widget _infoSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}