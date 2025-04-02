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
import 'package:dartschat/services/firestore_service.dart';
import 'package:logger/logger.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  final void Function(Locale) onLocaleChange;

  const MainPage({super.key, this.initialIndex = 0, required this.onLocaleChange});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  final Logger _logger = Logger();
  final FirestoreService _firestoreService = FirestoreService();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _logger.i("MainPage initialized with initialIndex: $_selectedIndex");

    _pages = [
      HomePage(onLocaleChange: widget.onLocaleChange),
      FriendsPage(onLocaleChange: widget.onLocaleChange),
      ChatListPage(onLocaleChange: widget.onLocaleChange),
      ProfilePage(onLocaleChange: widget.onLocaleChange),
      MorePage(onLocaleChange: widget.onLocaleChange),
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
                builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange),
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
                builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange),
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
                builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange),
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
            builder: (context) => LoginPage(onLocaleChange: widget.onLocaleChange),
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
    String? userId = FirebaseAuth.instance.currentUser?.uid;

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
        child: StreamBuilder<int>(
          stream: userId != null
              ? FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: userId)
              .snapshots()
              .asyncMap((snapshot) => _firestoreService.getTotalUnreadCount(userId))
              .distinct()
              : Stream.value(0),
          builder: (context, snapshot) {
            int totalUnreadCount = snapshot.data ?? 0;
            _logger.i("네비게이션 바 배지 업데이트: $totalUnreadCount개의 읽지 않은 메시지, userId: $userId");
            return BottomNavigationBar(
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
                  icon: Stack(
                    children: [
                      const Icon(Icons.chat, size: 28),
                      if (totalUnreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$totalUnreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Icon(Icons.chat, size: 32),
                      if (totalUnreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$totalUnreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
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
            );
          },
        ),
      ),
    );
  }
}