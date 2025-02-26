import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'friends_page.dart';
import 'more_page.dart';

class MainPage extends StatefulWidget {
  final int initialIndex; // ✅ 처음 로딩될 탭을 설정할 수 있도록 추가

  const MainPage({super.key, this.initialIndex = 0}); // ✅ 기본값을 HomePage(전체)로 설정

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;

  // ✅ 각 페이지를 미리 생성하여 페이지 유지 (네비게이션 바 사라짐 방지)
  final List<Widget> _pages = [
    const HomePage(),
    const FriendsPage(),
    const ChatListPage(),
    const ProfilePage(), // ✅ ProfilePage 인스턴스 유지
    const MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // ✅ 초기 선택된 탭 설정
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // ✅ 선택된 페이지 표시
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // ✅ 배경 화이트
          border: const Border(
            top: BorderSide(color: Colors.blueAccent, width: 2), // ✅ 상단 테두리 강조 (네온 블루)
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // ✅ 그림자 효과 추가
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white, // ✅ 네비게이션 바 배경 색상
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blueAccent, // ✅ 네온 블루 포인트 컬러
          unselectedItemColor: Colors.grey[500], // ✅ 미선택 시 연한 회색
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
