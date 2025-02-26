import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({Key? key}) : super(key: key);

  @override
  _GroupCreatePageState createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _groupNameController = TextEditingController();
  File? _selectedImage;
  bool _isCreating = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("그룹 이름을 입력하세요.")),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      String fileName = "group_${DateTime.now().millisecondsSinceEpoch}.jpg";
      try {
        TaskSnapshot snapshot = await _storage.ref().child("group_images/$fileName").putFile(_selectedImage!);
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이미지 업로드 실패: $e")),
        );
      }
    }

    await _firestoreService.createGroup(
      groupName: _groupNameController.text.trim(),
      groupImage: imageUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("그룹이 생성되었습니다.")),
    );

    Navigator.pop(context);

    setState(() {
      _isCreating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("그룹 생성"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null ? const Icon(Icons.camera_alt, size: 50) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "그룹 이름",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                child: _isCreating ? const CircularProgressIndicator() : const Text("그룹 생성"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
