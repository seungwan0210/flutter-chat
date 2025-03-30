import 'package:flutter/material.dart';
import 'package:dartschat/generated/app_localizations.dart'; // 다국어 지원 추가
import 'package:url_launcher/url_launcher.dart';
import 'play_summary_page.dart';

class MorePage extends StatelessWidget {
  final void Function(Locale) onLocaleChange; // 언어 변경 콜백 추가

  const MorePage({Key? key, required this.onLocaleChange}) : super(key: key);

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.updateScheduled, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Text(AppLocalizations.of(context)!.comingSoon, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.confirm, style: TextStyle(color: Theme.of(context).primaryColor)),
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
      if (!launched) throw 'Could not launch $url';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.urlLaunchFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.more,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.of(context).size.width / 3 - 16,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final actions = [
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlaySummaryPage(onLocaleChange: onLocaleChange)), // onLocaleChange 전달
                    ),
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
                    AppLocalizations.of(context)!.todayPlaySummary,
                    AppLocalizations.of(context)!.tournamentInfo,
                    AppLocalizations.of(context)!.updateScheduled,
                    AppLocalizations.of(context)!.updateScheduled,
                    AppLocalizations.of(context)!.updateScheduled,
                    AppLocalizations.of(context)!.updateScheduled,
                  ][index], actions[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildImageBanner(context, 'assets/bulls_fighter.webp', 'https://m.dartskorea.com/'),
            _buildImageBanner(context, 'assets/dartslive.webp', 'https://www.dartslive.com/kr/'),
            _buildImageBanner(context, 'assets/phoenix.webp', 'https://www.phoenixdarts.com/kr'),
            const SizedBox(height: 40),
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