import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class DartboardPage extends StatefulWidget {
  const DartboardPage({super.key});

  @override
  _DartboardPageState createState() => _DartboardPageState();
}

class _DartboardPageState extends State<DartboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedDartBoard = "다트라이브";
  bool _isSaving = false;
  List<String> _dartBoards = ["다트라이브", "피닉스", "그란보드", "홈보드"];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDartboard();
    _loadDartboardList();
  }

  /// Firestore에서 현재 사용자의 다트보드 설정 가져오기
  Future<void> _loadDartboard() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedDartBoard = userData["dartBoard"] ?? "다트라이브";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "다트보드 설정을 불러오는 중 오류가 발생했습니다: $e";
        });
      }
    }
  }

  /// Firestore에서 다트보드 목록 불러오기
  Future<void> _loadDartboardList() async {
    try {
      List<String> boards = await _firestoreService.getDartboardList();
      if (boards.isNotEmpty && mounted) {
        setState(() {
          _dartBoards = boards;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = "다트보드 목록을 불러올 수 없습니다.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "다트보드 목록을 불러오는 중 오류가 발생했습니다: $e";
        });
      }
    }
  }

  /// 선택한 다트보드 저장
  Future<void> _saveDartboard() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _firestoreService.updateUserData({
        "dartBoard": _selectedDartBoard,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("다트보드가 변경되었습니다.")),
        );
        Navigator.pop(context, _selectedDartBoard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "다트보드 저장 중 오류가 발생했습니다: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "다트보드 설정",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _errorMessage != null
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
                  : _dartBoards.isEmpty
                  ? Center(
                child: Text(
                  "다트보드 목록을 불러올 수 없습니다.",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _dartBoards.length,
                itemBuilder: (context, index) {
                  String dartBoard = _dartBoards[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<String>(
                      title: Text(
                        dartBoard,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: dartBoard,
                      groupValue: _selectedDartBoard,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDartBoard = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedDartBoard == dartBoard,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage != null && _dartBoards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDartboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                      : Text(
                    "저장하기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}