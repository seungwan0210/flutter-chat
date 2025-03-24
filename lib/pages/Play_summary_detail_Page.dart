import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PlaySummaryDetailPage extends StatefulWidget {
  final DateTime selectedDate;

  const PlaySummaryDetailPage({super.key, required this.selectedDate});

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

  // 이모티콘 목록
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
    String date = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
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
        "emoji": _selectedEmoji, // 이모티콘 저장
      };

      if (snapshot.exists) {
        await summaryRef.set(newData, SetOptions(merge: true));
      } else {
        await summaryRef.set(newData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("플레이 요약이 저장되었습니다!")),
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
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "플레이 요약 작성",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEmojiSelector(),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField(_gamesPlayedController, "경기 수", TextInputType.number),
                    const SizedBox(height: 20),
                    _buildTextField(_bestPerformanceController, "오늘 가장 잘된 점"),
                    const SizedBox(height: 20),
                    _buildTextField(_improvementController, "오늘 개선할 점"),
                    const SizedBox(height: 20),
                    _buildTextField(_memoController, "한 줄 메모"),
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
                    _buildButton("저장하기", _savePlaySummary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 이모티콘 선택 UI (한 줄로 표시, 크기 조정)
  Widget _buildEmojiSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "오늘의 플레이 상태",
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 패딩 축소
                decoration: BoxDecoration(
                  color: _selectedEmoji == entry.key ? Theme.of(context).primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedEmoji == entry.key ? Theme.of(context).primaryColor : Colors.grey.shade400,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 20), // 이모티콘 크기 축소
                    ),
                    const SizedBox(width: 4), // 간격 축소
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12, // 텍스트 크기 축소
                        color: _selectedEmoji == entry.key ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
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
        return DropdownMenuItem(value: board, child: Text(board));
      }).toList(),
      onChanged: (value) => setState(() => _selectedBoard = value!),
      decoration: InputDecoration(
        labelText: "플레이한 보드",
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
}