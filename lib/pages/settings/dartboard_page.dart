import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class DartboardPage extends StatefulWidget {
  const DartboardPage({super.key});

  @override
  _DartboardPageState createState() => _DartboardPageState();
}

class _DartboardPageState extends State<DartboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedDartBoard = "다트라이브"; // ✅ 기본값 설정
  bool _isSaving = false;
  List<String> _dartBoards = ["다트라이브", "피닉스", "그란보드", "홈보드"]; // ✅ 기본 목록

  @override
  void initState() {
    super.initState();
    _loadDartboard();
    _loadDartboardList();
  }

  /// ✅ Firestore에서 현재 사용자의 다트보드 설정 가져오기
  Future<void> _loadDartboard() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _selectedDartBoard = userData["dartBoard"] ?? "다트라이브";
      });
    }
  }

  /// ✅ Firestore에서 다트보드 목록 불러오기
  Future<void> _loadDartboardList() async {
    List<String> boards = await _firestoreService.getDartboardList();
    if (boards.isNotEmpty && mounted) {
      setState(() {
        _dartBoards = boards;
      });
    }
  }

  /// ✅ 선택한 다트보드 저장
  Future<void> _saveDartboard() async {
    setState(() => _isSaving = true);

    await _firestoreService.updateUserData({
      "dartBoard": _selectedDartBoard,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("다트보드가 변경되었습니다.")),
      );
      Navigator.pop(context, _selectedDartBoard); // ✅ 변경된 값을 반환하여 업데이트
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("다트보드 설정"),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDartboard,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _dartBoards.length,
        itemBuilder: (context, index) {
          String dartBoard = _dartBoards[index];
          return RadioListTile<String>(
            title: Text(dartBoard),
            value: dartBoard,
            groupValue: _selectedDartBoard,
            onChanged: (value) {
              setState(() {
                _selectedDartBoard = value!;
              });
            },
          );
        },
      ),
    );
  }
}
