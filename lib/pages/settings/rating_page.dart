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
  int _maxRating = 20; // 기본 레이팅 범위

  @override
  void initState() {
    super.initState();
    _loadRating();
    _loadMaxRating(); // ✅ Firestore에서 최대 레이팅 범위 가져오기
  }

  /// ✅ Firestore에서 현재 사용자의 레이팅 값 가져오기
  Future<void> _loadRating() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _selectedRating = userData["rating"] ?? 1;
      });
    }
  }

  /// ✅ Firestore에서 최대 레이팅 범위 가져오기
  Future<void> _loadMaxRating() async {
    int maxRating = await _firestoreService.getMaxRating();
    if (maxRating > 0 && mounted) {
      setState(() {
        _maxRating = maxRating;
      });
    }
  }

  /// ✅ 선택한 레이팅 저장
  Future<void> _saveRating() async {
    setState(() => _isSaving = true);

    await _firestoreService.updateUserData({
      "rating": _selectedRating,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("레이팅이 변경되었습니다.")),
      );
      Navigator.pop(context, _selectedRating); // ✅ 변경된 값을 반환하여 업데이트 유도
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("레이팅 설정"),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRating,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _maxRating + 1, // ✅ Firestore에서 가져온 최대 레이팅 값 사용
        itemBuilder: (context, index) {
          return RadioListTile<int>(
            title: Text("레이팅 $index"),
            value: index,
            groupValue: _selectedRating,
            onChanged: (value) {
              setState(() {
                _selectedRating = value!;
              });
            },
          );
        },
      ),
    );
  }
}
