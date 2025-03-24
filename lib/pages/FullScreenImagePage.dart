import 'package:flutter/material.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
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
    print("FullScreenImagePage - imageUrls: ${widget.imageUrls}");
    print("FullScreenImagePage - initialIndex: ${widget.initialIndex}");
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            widget.imageUrls.isEmpty
                ? Center(
              child: Icon(
                Icons.person,
                size: 140,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
                : PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                print("FullScreenImagePage - Page changed to: $index");
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
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
            // 현재 위치 표시 (예: 1/3), imageUrls가 비어 있지 않을 때만 표시
            if (widget.imageUrls.isNotEmpty)
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
          ],
        ),
      ),
    );
  }
}