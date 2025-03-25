import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartschat/pages/home_page.dart';
import 'package:dartschat/pages/friends_page.dart';
import 'package:dartschat/pages/chat_list_page.dart';
import 'package:dartschat/pages/profile_page.dart';
import 'package:dartschat/pages/more_page.dart';
import 'package:dartschat/pages/login_page.dart';
import 'package:logger/logger.dart'; // Logger 패키지 추가 필요

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  final Logger _logger = Logger(); // Logger 인스턴스 추가

  final List<Widget> _pages = [
    const HomePage(),
    const FriendsPage(),
    const ChatListPage(),
    const ProfilePage(),
    const MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _logger.i("MainPage initialized with initialIndex: ${_selectedIndex}");
    _checkAccountStatus();
  }

  /// 계정 활성화 상태 확인
  Future<void> _checkAccountStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _logger.i("Checking account status for UID: ${user.uid}");
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      bool isActive = userDoc.exists && (userDoc["isActive"] ?? true);
      _logger.i("User document exists: ${userDoc.exists}, isActive: $isActive");

      if (!isActive) {
        _logger.w("User is inactive, signing out and redirecting to LoginPage");
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _logger.i("User is active, staying on MainPage");
      }
    } else {
      _logger.w("No user logged in, redirecting to LoginPage");
      Navigator.pushReplacementNamed(context, '/login');
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              activeIcon: Icon(Icons.home, size: 32),
              label: "전체",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group, size: 28),
              activeIcon: Icon(Icons.group, size: 32),
              label: "친구",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat, size: 28),
              activeIcon: Icon(Icons.chat, size: 32),
              label: "채팅",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              activeIcon: Icon(Icons.person, size: 32),
              label: "프로필",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz, size: 28),
              activeIcon: Icon(Icons.more_horiz, size: 32),
              label: "더보기",
            ),
          ],
        ),
      ),
    );
  }
}