import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class HomeShopPage extends StatefulWidget {
  const HomeShopPage({Key? key}) : super(key: key);

  @override
  _HomeShopPageState createState() => _HomeShopPageState();
}

class _HomeShopPageState extends State<HomeShopPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _homeShopController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHomeShop();
  }

  /// Firestore에서 현재 홈샵 정보 가져오기
  Future<void> _loadHomeShop() async {
    Map<String, dynamic>? userData = await _firestoreService.getUserData();
    if (userData != null) {
      setState(() {
        _homeShopController.text = userData["homeShop"] ?? "";
      });
    }
  }

  /// 홈샵 유효성 검사 (2~30자 제한)
  bool _isValidHomeShop(String homeShop) {
    return homeShop.length >= 2 && homeShop.length <= 30;
  }

  /// 홈샵 저장 기능
  Future<void> _saveHomeShop() async {
    String newHomeShop = _homeShopController.text.trim();

    if (newHomeShop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("홈샵을 입력해주세요.")),
      );
      return;
    }

    if (!_isValidHomeShop(newHomeShop)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("홈샵은 2~30자 사이로 입력해주세요.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    await _firestoreService.updateUserData({"homeShop": newHomeShop});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("홈샵이 변경되었습니다.")),
    );

    Navigator.pop(context, newHomeShop); // ✅ 변경된 홈샵을 반환하여 업데이트 유도
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("홈샵 변경"),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveHomeShop,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _homeShopController,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: "새 홈샵",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveHomeShop,
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }
}


