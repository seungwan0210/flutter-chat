import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'play_summary_history_page.dart';

class PlaySummaryPage extends StatefulWidget {
  const PlaySummaryPage({super.key});

  @override
  State<PlaySummaryPage> createState() => _PlaySummaryPageState();
}

class _PlaySummaryPageState extends State<PlaySummaryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _gamesPlayedController = TextEditingController();
  final TextEditingController _bestPerformanceController = TextEditingController();
  final TextEditingController _improvementController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String _selectedBoard = "다트라이브3";
  bool _isLoading = false;

  /// ✅ **Firestore에서 기존 데이터가 있으면 유지한 채로 업데이트**
  Future<void> _savePlaySummary() async {
    if (_gamesPlayedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("경기 수를 입력해주세요!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    String userId = _auth.currentUser!.uid;
    String today = DateTime.now().toString().split(" ")[0];
    DocumentReference summaryRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("daily_play_summary")
        .doc(today);

    try {
      DocumentSnapshot snapshot = await summaryRef.get();

      Map<String, dynamic> newData = {
        "date": today,
        "board": _selectedBoard,
        "games_played": int.parse(_gamesPlayedController.text),
        "best_performance": _bestPerformanceController.text,
        "improvements": _improvementController.text,
        "memo": _memoController.text,
      };

      if (snapshot.exists) {
        await summaryRef.set(newData, SetOptions(merge: true));
      } else {
        await summaryRef.set(newData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오늘의 플레이 요약이 저장되었습니다!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("오늘의 플레이 요약", style: TextStyle(color: Colors.white)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// ✅ 스크롤 가능하도록 `Expanded` 적용
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDropdown(),
                            _buildTextField(_gamesPlayedController, "경기 수", TextInputType.number),
                            _buildTextField(_bestPerformanceController, "오늘 가장 잘된 점"),
                            _buildTextField(_improvementController, "오늘 개선할 점"),
                            _buildTextField(_memoController, "한 줄 메모"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// ✅ 버튼을 하단에 고정
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton("저장하기", _savePlaySummary),
                      const SizedBox(width: 12),
                      _buildButton("히스토리 보기", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PlaySummaryHistoryPage()),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField(
      value: _selectedBoard,
      items: ["다트라이브3", "피닉스", "그란보드", "홈보드"].map((board) {
        return DropdownMenuItem(value: board, child: Text(board));
      }).toList(),
      onChanged: (value) => setState(() => _selectedBoard = value!),
      decoration: const InputDecoration(labelText: "플레이한 보드"),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
