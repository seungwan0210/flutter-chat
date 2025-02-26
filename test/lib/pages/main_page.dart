import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'friends_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // ✅ 기본 선택 탭 (홈)

  final List<Widget> _pages = [
    const HomePage(),
    const FriendsPage(),
    const ChatListPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( // ✅ 화면 밖으로 UI가 나가지 않도록 보호
        child: Column(
          children: [
            Expanded( // ✅ 화면 크기에 맞게 자동 조절
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // ✅ 배경색 추가
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1), // ✅ 상단 테두리 추가
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blueAccent, // ✅ 선택된 아이콘 색상
          unselectedItemColor: Colors.grey, // ✅ 선택되지 않은 아이콘 색상
          type: BottomNavigationBarType.fixed, // ✅ 네비게이션 바 고정
          showSelectedLabels: true, // ✅ 선택된 항목 라벨 표시
          showUnselectedLabels: false, // ✅ 선택되지 않은 항목 라벨 숨김 (더 깔끔한 UI)
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: _selectedIndex == 0 ? 30 : 24, // ✅ 선택된 아이콘 크기 변경
              ),
              label: "홈",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.group,
                size: _selectedIndex == 1 ? 30 : 24,
              ),
              label: "친구",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.chat,
                size: _selectedIndex == 2 ? 30 : 24,
              ),
              label: "채팅",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: _selectedIndex == 3 ? 30 : 24,
              ),
              label: "프로필",
            ),
          ],
        ),
      ),
    );
  }
}
