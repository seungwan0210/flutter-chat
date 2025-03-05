import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaySummaryHistoryPage extends StatefulWidget {
  const PlaySummaryHistoryPage({super.key});

  @override
  State<PlaySummaryHistoryPage> createState() => _PlaySummaryHistoryPageState();
}

class _PlaySummaryHistoryPageState extends State<PlaySummaryHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "내 플레이 요약 기록",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF182848)],
          ),
        ),
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
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                var summaries = snapshot.data!.docs;

                if (summaries.isEmpty) {
                  return const Center(
                    child: Text(
                      "아직 저장된 기록이 없습니다!",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    var summary = summaries[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          "${summary["date"]} - ${summary["board"]}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          "경기 수: ${summary["games_played"]} | 메모: ${summary["memo"]}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.blueAccent),
                        onTap: () => _showSummaryDetail(summary),
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

  /// ✅ 다이얼로그 - 스크롤 추가 & 섹션 스타일 업데이트
  void _showSummaryDetail(QueryDocumentSnapshot summary) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7, // ✅ 최대 높이 설정
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ 제목 (날짜 & 다트보드명)
                Text(
                  "${summary["date"]} - ${summary["board"]}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ✅ 스크롤 가능하게 변경
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoSection("경기 수", summary["games_played"].toString()),
                        _infoSection("오늘 가장 잘된 점", summary["best_performance"]),
                        _infoSection("오늘 개선할 점", summary["improvements"]),
                        _infoSection("메모", summary["memo"]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ 버튼 (닫기 & 삭제)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("닫기"),
                    ),
                    TextButton(
                      onPressed: () => _deleteSummary(summary.id),
                      child: const Text("삭제",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
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

  /// ✅ 데이터 삭제 기능
  Future<void> _deleteSummary(String summaryId) async {
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
  }

  /// ✅ 정보 섹션 스타일 개선
  Widget _infoSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, // ✅ 제목
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
          ),
          const SizedBox(height: 4),
          Text(
            value, // ✅ 내용
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(), // ✅ 섹션 구분선 추가
        ],
      ),
    );
  }
}
