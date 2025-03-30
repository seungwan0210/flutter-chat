import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartschat/generated/app_localizations.dart';
import 'package:dartschat/pages/home_page.dart';
import 'package:dartschat/pages/friends_page.dart';
import 'package:dartschat/pages/chat_list_page.dart';
import 'package:dartschat/pages/profile_page.dart';
import 'package:dartschat/pages/more_page.dart';
import 'package:dartschat/pages/login_page.dart';
import 'package:logger/logger.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  final void Function(Locale) onLocaleChange; // 필수로 유지

  const MainPage({super.key, this.initialIndex = 0, required this.onLocaleChange});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  final Logger _logger = Logger();

  late List<Widget> _pages; // late로 선언하여 initState에서 초기화

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _logger.i("MainPage initialized with initialIndex: $_selectedIndex");

    // _pages 리스트를 initState에서 초기화하여 onLocaleChange 전달
    _pages = [
      HomePage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
      FriendsPage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
      ChatListPage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
      ProfilePage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
      MorePage(onLocaleChange: widget.onLocaleChange), // onLocaleChange 전달
    ];

    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _logger.i("Checking account status for UID: ${user.uid}");
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
        if (!userDoc.exists) {
          _logger.w("User document does not exist for UID: ${user.uid}, redirecting to LoginPage");
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  onLocaleChange: widget.onLocaleChange,
                ),
              ),
            );
          }
          return;
        }

        int blockedByCount = userDoc["blockedByCount"] ?? 0;
        bool isActive = userDoc["isActive"] ?? true;

        _logger.i("User document exists: ${userDoc.exists}, blockedByCount: $blockedByCount, isActive: $isActive");

        if (blockedByCount >= 10 && isActive) {
          await FirebaseFirestore.instance.collection("users").doc(user.uid).update({"isActive": false});
          _logger.w("User ${user.uid} blocked 10+ times, deactivated account.");
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  onLocaleChange: widget.onLocaleChange,
                ),
              ),
            );
          }
          return;
        }

        if (!isActive) {
          _logger.w("User is inactive, signing out and redirecting to LoginPage");
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  onLocaleChange: widget.onLocaleChange,
                ),
              ),
            );
          }
        } else {
          _logger.i("User is active, staying on MainPage");
        }
      } catch (e) {
        _logger.e("Error checking account status: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocalizations.of(context)!.loginFailed}: $e")),
          );
        }
      }
    } else {
      _logger.w("No user logged in, redirecting to LoginPage");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              onLocaleChange: widget.onLocaleChange,
            ),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _logger.i("Bottom navigation item tapped: $index");
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("Building MainPage with selectedIndex: $_selectedIndex");
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.black,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor ?? Colors.grey.shade300, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Colors.amber[700],
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.white,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, size: 28),
              activeIcon: const Icon(Icons.home, size: 32),
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.group, size: 28),
              activeIcon: const Icon(Icons.group, size: 32),
              label: AppLocalizations.of(context)!.friends,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat, size: 28),
              activeIcon: const Icon(Icons.chat, size: 32),
              label: AppLocalizations.of(context)!.chat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person, size: 28),
              activeIcon: const Icon(Icons.person, size: 32),
              label: AppLocalizations.of(context)!.profile,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz, size: 28),
              activeIcon: const Icon(Icons.more_horiz, size: 32),
              label: AppLocalizations.of(context)!.more,
            ),
          ],
        ),
      ),
    );
  }
}