import 'package:flutter/material.dart';
import 'package:dartschat/pages/home_page.dart';
import 'package:dartschat/pages/friends_page.dart';
import 'package:dartschat/pages/chat_list_page.dart';
import 'package:dartschat/pages/profile_page.dart';
import 'package:dartschat/pages/more_page.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;

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
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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