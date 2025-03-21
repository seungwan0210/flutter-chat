import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';

class ProfileImagePage extends StatefulWidget {
  const ProfileImagePage({super.key});

  @override
  _ProfileImagePageState createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileImages();
  }

  /// Firestore에서 기존 프로필 이미지 리스트 로드
  Future<void> _loadProfileImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null) {
        List<Map<String, dynamic>> images = List<Map<String, dynamic>>.from(userData['profileImages'] ?? []);
        // 타임스탬프 기준으로 내림차순 정렬 (최신순)
        images.sort((a, b) {
          DateTime dateA = DateTime.parse(a['timestamp'] ?? '1970-01-01T00:00:00');
          DateTime dateB = DateTime.parse(b['timestamp'] ?? '1970-01-01T00:00:00');
          return dateB.compareTo(dateA); // 최신 날짜가 먼저 오도록
        });
        setState(() {
          _profileImages = images;
          _mainProfileImage = userData['mainProfileImage'] ?? (_profileImages.isNotEmpty ? _profileImages.first['url'] : null);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "프로필 이미지를 불러오는 중 오류가 발생했습니다: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        File imageFile = File(pickedFile.path);
        await _uploadImage(imageFile);
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

  /// 이미지 업로드 및 Firestore에 추가
  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> imageData = await _firestoreService.uploadProfileImage(imageFile);
      setState(() {
        _profileImages.add(imageData);
        // 타임스탬프 기준으로 내림차순 정렬 (최신순)
        _profileImages.sort((a, b) {
          DateTime dateA = DateTime.parse(a['timestamp'] ?? '1970-01-01T00:00:00');
          DateTime dateB = DateTime.parse(b['timestamp'] ?? '1970-01-01T00:00:00');
          return dateB.compareTo(dateA);
        });
        _mainProfileImage = imageData['url']; // 가장 최근 이미지를 대표 이미지로 설정
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지가 업로드되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "이미지 업로드 중 오류가 발생했습니다: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 이미지 삭제
  Future<void> _deleteImage(String imageUrl) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.deleteProfileImage(imageUrl);
      setState(() {
        _profileImages.removeWhere((item) => item['url'] == imageUrl);
        if (_mainProfileImage == imageUrl) {
          _mainProfileImage = _profileImages.isNotEmpty ? _profileImages.first['url'] : null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지가 삭제되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "이미지 삭제 중 오류가 발생했습니다: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 대표 이미지 설정
  Future<void> _setMainImage(String imageUrl) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.setMainProfileImage(imageUrl);
      setState(() {
        _mainProfileImage = imageUrl;
        // 대표 이미지를 리스트의 맨 위로 이동
        int index = _profileImages.indexWhere((item) => item['url'] == imageUrl);
        if (index != -1) {
          var selectedImage = _profileImages.removeAt(index);
          _profileImages.insert(0, selectedImage);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("대표 이미지가 설정되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "대표 이미지 설정 중 오류가 발생했습니다: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading
                ? null
                : () {
              // 첫 번째 이미지를 반환 (호환성을 위해)
              String? firstImage = _mainProfileImage;
              Navigator.pop(context, firstImage);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_profileImages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("아직 업로드된 이미지가 없습니다."),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _profileImages.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> imageData = _profileImages[index];
                    String imageUrl = imageData['url'];
                    String timestamp = imageData['timestamp'] ?? '';
                    bool isMainImage = imageUrl == _mainProfileImage;

                    // 타임스탬프에서 날짜만 추출 (YYYY-MM-DD)
                    String dateOnly = '';
                    if (timestamp.isNotEmpty) {
                      DateTime dateTime = DateTime.parse(timestamp);
                      dateOnly = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImagePage(
                                  imageUrls: _profileImages.map((img) => img['url'] as String).toList(),
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(imageUrl),
                          ),
                        ),
                        title: Text(
                          dateOnly.isNotEmpty ? dateOnly : '날짜 정보 없음',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: isMainImage,
                              onChanged: (value) {
                                if (value == true) {
                                  _setMainImage(imageUrl);
                                }
                              },
                            ),
                            TextButton(
                              onPressed: () => _deleteImage(imageUrl),
                              child: const Text(
                                "삭제",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Theme.of(context).disabledColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "이미지 추가",
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

// 전체 화면 이미지 보기 페이지 (여러 장 넘겨보기 지원)
class FullScreenImagePage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                height: double.infinity,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error, color: Colors.white));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}