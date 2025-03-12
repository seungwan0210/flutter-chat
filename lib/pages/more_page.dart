import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'play_summary_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({Key? key}) : super(key: key);

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('업데이트 예정', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Text('추후 업데이트 예정입니다.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL 열기 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('더보기', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView( // 스크롤 가능성 추가
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // GridView 자체는 스크롤 방지, 외부 SingleChildScrollView로 대체
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.of(context).size.width / 3 - 16, // 3열 기준, 간격 고려
                  crossAxisSpacing: 8, // 간격 줄임
                  mainAxisSpacing: 8, // 간격 줄임
                  childAspectRatio: 1, // 정사각형 비율 유지
                ),
                itemCount: 6, // 총 6개 아이콘
                itemBuilder: (context, index) {
                  final actions = [
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaySummaryPage())),
                        () => _showUpdateDialog(context),
                        () => _showUpdateDialog(context),
                        () => _showUpdateDialog(context),
                        () => _showUpdateDialog(context),
                        () => _showUpdateDialog(context),
                  ];
                  return _buildIconButton(context, [
                    Icons.bar_chart,
                    Icons.emoji_events,
                    Icons.update,
                    Icons.update,
                    Icons.update,
                    Icons.update,
                  ][index], [
                    '오늘의 플레이',
                    '토너먼트 정보',
                    '업데이트 예정',
                    '업데이트 예정',
                    '업데이트 예정',
                    '업데이트 예정',
                  ][index], actions[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildImageBanner(context, 'assets/bulls_fighter.webp', 'https://m.dartskorea.com/'),
            _buildImageBanner(context, 'assets/dartslive.webp', 'https://www.dartslive.com/kr/'),
            _buildImageBanner(context, 'assets/phoenix.webp', 'https://www.phoenixdarts.com/kr'),
            const SizedBox(height: 40), // 하단 여백 확보
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 2,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner(BuildContext context, String imagePath, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _launchURL(context, url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
                offset: const Offset(2, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) => const Icon(Icons.error, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}