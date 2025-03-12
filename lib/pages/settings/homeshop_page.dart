import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가 (선택적)
import '../../services/firestore_service.dart';

class HomeShopPage extends StatefulWidget {
  const HomeShopPage({super.key});

  @override
  _HomeShopPageState createState() => _HomeShopPageState();
}

class _HomeShopPageState extends State<HomeShopPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _homeShopController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeShop();
  }

  /// Firestore에서 현재 사용자의 홈샵 정보 가져오기
  Future<void> _loadHomeShop() async {
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _homeShopController.text = userData["homeShop"] ?? "";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "홈샵 정보를 불러오는 중 오류가 발생했습니다: $e";
        });
      }
    }
  }

  /// 홈샵 유효성 검사 (실시간 반영)
  bool _isValidHomeShop(String homeShop) {
    return homeShop.trim().length >= 2 && homeShop.trim().length <= 30;
  }

  /// 입력 중 실시간 유효성 검사
  void _validateHomeShop(String value) {
    if (value.isNotEmpty && !_isValidHomeShop(value)) {
      setState(() {
        _errorMessage = "홈샵은 2~30자 사이로 입력해주세요.";
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// 홈샵 저장 기능
  Future<void> _saveHomeShop() async {
    String newHomeShop = _homeShopController.text.trim();

    if (newHomeShop.isEmpty) {
      setState(() => _errorMessage = "홈샵을 입력해주세요!");
      return;
    }

    if (!_isValidHomeShop(newHomeShop)) {
      setState(() => _errorMessage = "홈샵은 2~30자 사이로 입력해주세요.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateUserData({"homeShop": newHomeShop});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("홈샵이 변경되었습니다.")),
        );
        _homeShopController.clear();
        Navigator.pop(context, newHomeShop);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "홈샵 저장 중 오류가 발생했습니다: $e";
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
          "홈샵 변경",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          _isSaving
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
          )
              : IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: _isSaving ? null : _saveHomeShop,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              TextField(
                controller: _homeShopController,
                maxLength: 30,
                onChanged: _validateHomeShop, // 실시간 유효성 검사
                decoration: InputDecoration(
                  labelText: "새 홈샵",
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  errorText: _errorMessage,
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveHomeShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Theme.of(context).disabledColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "저장",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _homeShopController.dispose();
    super.dispose();
  }
}