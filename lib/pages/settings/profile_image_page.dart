import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import 'package:dartschat/pages/FullScreenImagePage.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:logger/logger.dart';

class ProfileImagePage extends StatefulWidget {
  const ProfileImagePage({super.key});

  @override
  _ProfileImagePageState createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _profileImages = [];
  String? _mainProfileImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileImages();
    _logger.i("ProfileImagePage initState called");
  }

  @override
  void dispose() {
    _logger.i("ProfileImagePage dispose called");
    super.dispose();
  }

  Future<void> _loadProfileImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        List<Map<String, dynamic>> images = List<Map<String, dynamic>>.from(userData['profileImages'] ?? []);
        images.sort((a, b) {
          DateTime dateA = DateTime.parse(a['timestamp'] ?? '1970-01-01T00:00:00');
          DateTime dateB = DateTime.parse(b['timestamp'] ?? '1970-01-01T00:00:00');
          return dateB.compareTo(dateA);
        });
        setState(() {
          _profileImages = images;
          _mainProfileImage = userData['mainProfileImage'] ?? (_profileImages.isNotEmpty ? _profileImages.first['url'] : null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorLoadingProfileImages}: $e";
        });
      }
      _logger.e("Error loading profile images: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        File imageFile = File(pickedFile.path);
        await _uploadImage(imageFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorPickingImage}: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      _logger.e("Error picking image: $e");
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> imageData = await _firestoreService.uploadProfileImage(imageFile);
      setState(() {
        _profileImages.insert(0, imageData); // 최신 이미지를 맨 처음에 추가
        _mainProfileImage = imageData['url']; // 자동으로 대표 이미지 설정
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.imageUploaded)),
        );
      }
      _logger.i("Image uploaded: ${imageData['url']}");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorUploadingImage}: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      _logger.e("Error uploading image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          SnackBar(content: Text(AppLocalizations.of(context)!.imageDeleted)),
        );
      }
      _logger.i("Image deleted: $imageUrl");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorDeletingImage}: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      _logger.e("Error deleting image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setMainImage(String imageUrl) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.setMainProfileImage(imageUrl);
      setState(() {
        _mainProfileImage = imageUrl;
        int index = _profileImages.indexWhere((item) => item['url'] == imageUrl);
        if (index != -1) {
          var selectedImage = _profileImages.removeAt(index);
          _profileImages.insert(0, selectedImage);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mainImageSet)),
        );
      }
      _logger.i("Main image set: $imageUrl");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorSettingMainImage}: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      _logger.e("Error setting main image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setDefaultImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.setMainProfileImage(null);
      setState(() {
        _mainProfileImage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.defaultImageSet)),
        );
        Navigator.pop(context, null);
      }
      _logger.i("Default image set");
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "${AppLocalizations.of(context)!.errorSettingDefaultImage}: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      _logger.e("Error setting default image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileImageSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: _profileImages.isEmpty
                    ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noImagesUploaded,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _profileImages.length + 1, // +1 for default image
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Default image tile
                      bool isMainImage = _mainProfileImage == null;
                      return GestureDetector(
                        onTap: () => _setDefaultImage(),
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImagePage(
                                imageUrls: ["default"],
                                initialIndex: 0,
                                isDefaultImage: true,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: isMainImage ? Theme.of(context).primaryColor.withOpacity(0.2) : Theme.of(context).cardColor,
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              if (isMainImage)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.star,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  AppLocalizations.of(context)!.defaultImage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final imageIndex = index - 1;
                    Map<String, dynamic> imageData = _profileImages[imageIndex];
                    String? imageUrl = imageData['url'];
                    String timestamp = imageData['timestamp'] ?? '';
                    bool isMainImage = imageUrl == _mainProfileImage;

                    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();

                    String dateOnly = timestamp.isNotEmpty
                        ? "${DateTime.parse(timestamp).year}-${DateTime.parse(timestamp).month.toString().padLeft(2, '0')}-${DateTime.parse(timestamp).day.toString().padLeft(2, '0')}"
                        : '';

                    return GestureDetector(
                      onTap: () => _setMainImage(imageUrl),
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImagePage(
                              imageUrls: [imageUrl],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: isMainImage ? Theme.of(context).primaryColor.withOpacity(0.2) : Theme.of(context).cardColor,
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.error,
                                size: 80,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            if (isMainImage)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.star,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateOnly.isNotEmpty ? dateOnly : AppLocalizations.of(context)!.noDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteImage(imageUrl),
                                  ),
                                ],
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
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    AppLocalizations.of(context)!.addImage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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