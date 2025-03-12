import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dartschat/services/firestore_service.dart';
import 'dart:io';

class ProfileImagePage extends StatefulWidget {
  const ProfileImagePage({super.key});

  @override
  _ProfileImagePageState createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isUploading = false;
  String? _errorMessage;

  /// 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _image = File(pickedFile.path);
          _errorMessage = null; // 이미지 선택 시 오류 메시지 초기화
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "이미지 선택이 취소되었거나 실패했습니다.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "이미지 선택 중 오류가 발생했습니다: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  /// Firebase Storage에 이미지 업로드 후 URL 반환
  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("profile_images/$fileName");
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("❌ 이미지 업로드 오류: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "이미지 업로드 중 오류가 발생했습니다: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      return null;
    }
  }

  /// 프로필 이미지 저장
  Future<void> _saveProfileImage() async {
    if (_image == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지를 선택해주세요.")),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    String? imageUrl = await _uploadImage(_image!);
    if (imageUrl != null) {
      try {
        await _firestoreService.updateUserData({"profileImage": imageUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("프로필 이미지가 변경되었습니다.")),
          );
          Navigator.pop(context, imageUrl);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Firestore 저장 중 오류가 발생했습니다: $e")),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "프로필 이미지 변경",
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Theme.of(context).cardColor,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Icon(Icons.camera_alt, size: 50, color: Theme.of(context).textTheme.bodyLarge?.color)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProfileImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Theme.of(context).disabledColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isUploading
                      ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                      : Text(
                    "저장",
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

  @override
  void dispose() {
    _image?.deleteSync(); // 안전한 파일 삭제
    _image = null; // 메모리 해제
    super.dispose();
  }
}