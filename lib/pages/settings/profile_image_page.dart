import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/firestore_service.dart';
import 'dart:io';

class ProfileImagePage extends StatefulWidget {
  const ProfileImagePage({Key? key}) : super(key: key);

  @override
  _ProfileImagePageState createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isUploading = false;

  /// ✅ 이미지 선택 (갤러리)
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// ✅ Firebase Storage에 이미지 업로드 후 URL 반환
  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("profile_images/$fileName");
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // ✅ 업로드 후 다운로드 URL 반환
    } catch (e) {
      print("❌ 이미지 업로드 오류: $e");
      return null;
    }
  }

  /// ✅ 프로필 이미지 저장
  Future<void> _saveProfileImage() async {
    if (_image == null) return;

    setState(() => _isUploading = true);

    String? imageUrl = await _uploadImage(_image!);
    if (imageUrl != null) {
      await _firestoreService.updateUserData({"profileImage": imageUrl});
      Navigator.pop(context, imageUrl); // ✅ 변경된 이미지 URL 반환
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("프로필 이미지 변경")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 70,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null
                  ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _isUploading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _saveProfileImage,
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }
}
