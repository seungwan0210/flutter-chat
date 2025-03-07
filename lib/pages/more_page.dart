import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'play_summary_page.dart'; // 오늘의 플레이 요약 페이지 import

class MorePage extends StatelessWidget {
  const MorePage({Key? key}) : super(key: key);

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('업데이트 예정'),
        content: Text('추후 업데이트 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault, // ✅ 기기별 최적화된 모드 사용
      );
      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('더보기', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 3, // 3x2 형식
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // 아이콘 영역 스크롤 방지
                children: [
                  _buildIconButton(context, Icons.bar_chart, '오늘의 플레이', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlaySummaryPage()),
                    );
                  }),
                  _buildIconButton(context, Icons.emoji_events, '토너먼트 정보', () {
                    _showUpdateDialog(context);
                  }),
                  _buildIconButton(context, Icons.update, '업데이트 예정', () {
                    _showUpdateDialog(context);
                  }),
                  _buildIconButton(context, Icons.update, '업데이트 예정', () {
                    _showUpdateDialog(context);
                  }),
                  _buildIconButton(context, Icons.update, '업데이트 예정', () {
                    _showUpdateDialog(context);
                  }),
                  _buildIconButton(context, Icons.update, '업데이트 예정', () {
                    _showUpdateDialog(context);
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildImageBanner('assets/bulls_fighter.webp', 'https://m.dartskorea.com/'),
          _buildImageBanner('assets/dartslive.webp', 'https://www.dartslive.com/kr/'),
          _buildImageBanner('assets/phoenix.webp', 'https://www.phoenixdarts.com/kr'),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blueAccent),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner(String imagePath, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
                offset: Offset(2, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
