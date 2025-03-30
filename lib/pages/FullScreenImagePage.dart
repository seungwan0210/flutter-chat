import 'package:flutter/material.dart';
import 'package:dartschat/generated/app_localizations.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool isDefaultImage;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.isDefaultImage = false,
  });

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            widget.imageUrls.isEmpty && !widget.isDefaultImage
                ? Center(
              child: Text(
                AppLocalizations.of(context)!.noImagesUploaded,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
                : PageView.builder(
              controller: _pageController,
              itemCount: widget.isDefaultImage ? 1 : widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: widget.isDefaultImage && index == 0
                        ? Icon(
                      Icons.person,
                      size: 140,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    )
                        : Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      height: double.infinity,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.error, color: Colors.white));
                      },
                    ),
                  ),
                );
              },
            ),
            if (!widget.isDefaultImage && widget.imageUrls.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_currentIndex + 1}/${widget.imageUrls.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.isDefaultImage)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.defaultImage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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