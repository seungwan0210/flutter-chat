import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String _selectedBoard = "다트라이브"; // 기본값 변경
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _gamesPlayedController.dispose();
    _bestPerformanceController.dispose();
    _improvementController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// Firestore에 플레이 요약 저장
  Future<void> _savePlaySummary() async {
    // 입력 검증 강화
    if (_gamesPlayedController.text.isEmpty) {
      setState(() => _errorMessage = "경기 수를 입력해주세요!");
      return;
    }
    if (_bestPerformanceController.text.isEmpty) {
      setState(() => _errorMessage = "오늘 가장 잘된 점을 입력해주세요!");
      return;
    }
    if (_improvementController.text.isEmpty) {
      setState(() => _errorMessage = "오늘 개선할 점을 입력해주세요!");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      setState(() {
        _errorMessage = "저장 실패: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("오늘의 플레이 요약", style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDropdown(),
                          const SizedBox(height: 10),
                          _buildTextField(_gamesPlayedController, "경기 수", TextInputType.number),
                          const SizedBox(height: 10),
                          _buildTextField(_bestPerformanceController, "오늘 가장 잘된 점"),
                          const SizedBox(height: 10),
                          _buildTextField(_improvementController, "오늘 개선할 점"),
                          const SizedBox(height: 10),
                          _buildTextField(_memoController, "한 줄 메모"),
                          if (_errorMessage != null) Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBoard,
      items: ["다트라이브", "피닉스", "그란보드", "홈보드"].map((board) { // 항목 변경
        return DropdownMenuItem(value: board, child: Text(board));
      }).toList(),
      onChanged: (value) => setState(() => _selectedBoard = value!),
      decoration: InputDecoration(
        labelText: "플레이한 보드",
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}