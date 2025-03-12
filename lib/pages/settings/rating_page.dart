import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedRating = 1; // 기본값
  bool _isSaving = false;
  bool _isLoaded = false;
  int _maxRating = 30; // 최대 레이팅을 30으로 변경
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRating();
    _loadMaxRating();
  }

  /// Firestore에서 현재 사용자의 레이팅 값 가져오기
  Future<void> _loadRating() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _selectedRating = userData["rating"] ?? 1;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "레이팅 값을 불러오는 중 오류가 발생했습니다: $e";
          _isLoaded = true;
        });
      }
    }
  }

  /// Firestore에서 최대 레이팅 범위 가져오기 (현재 30으로 고정)
  Future<void> _loadMaxRating() async {
    try {
      // Firestore에서 가져오는 대신 로컬에서 30으로 고정
      setState(() {
        _maxRating = 30; // Firestore 대신 30으로 설정
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "최대 레이팅 값을 불러오는 중 오류가 발생했습니다: $e";
        });
      }
    }
  }

  /// 선택한 레이팅 저장
  Future<void> _saveRating() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({
        "rating": _selectedRating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("레이팅이 변경되었습니다.")),
        );
        Navigator.pop(context, _selectedRating);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "레이팅 저장 중 오류가 발생했습니다: $e";
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
          "레이팅 설정",
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
              child: _errorMessage != null && !_isLoaded
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
                  : !_isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _maxRating,
                itemBuilder: (context, index) {
                  final rating = index + 1; // 1부터 시작
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: RadioListTile<int>(
                      title: Text(
                        "레이팅 $rating",
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      value: rating,
                      groupValue: _selectedRating,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRating = value;
                          });
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                      selected: _selectedRating == rating,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage != null && _isLoaded)
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
                  onPressed: _isSaving ? null : _saveRating,
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