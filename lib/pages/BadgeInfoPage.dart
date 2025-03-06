import 'package:flutter/material.dart';

class BadgeInfoPage extends StatelessWidget {
  const BadgeInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> badges = [
      {"name": "입문", "image": "assets/badges/skull.png", "requirement": "0회 조회"},
      {"name": "브론즈 1", "image": "assets/badges/bronze1.png", "requirement": "100회 조회"},
      {"name": "브론즈 2", "image": "assets/badges/bronze2.png", "requirement": "500회 조회"},
      {"name": "실버 1", "image": "assets/badges/silver1.png", "requirement": "1,000회 조회"},
      {"name": "실버 2", "image": "assets/badges/silver2.png", "requirement": "3,000회 조회"},
      {"name": "골드 1", "image": "assets/badges/gold1.png", "requirement": "5,000회 조회"},
      {"name": "골드 2", "image": "assets/badges/gold2.png", "requirement": "10,000회 조회"},
      {"name": "플래티넘", "image": "assets/badges/platinum.png", "requirement": "20,000회 조회"},
      {"name": "다이아몬드", "image": "assets/badges/diamond.png", "requirement": "30,000회 조회"},
      {"name": "마스터", "image": "assets/badges/master.png", "requirement": "50,000회 조회"},
      {"name": "레전드", "image": "assets/badges/legend.png", "requirement": "100,000회 조회"},
      {"name": "프로 선수", "image": "assets/badges/pro.png", "requirement": "관리자 지정"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("배지 정보")),
      body: ListView.builder(
        itemCount: badges.length,
        itemBuilder: (context, index) {
          var badge = badges[index];
          return ListTile(
            leading: Image.asset(badge["image"], width: 30, height: 30),
            title: Text(badge["name"]),
            subtitle: Text("획득 조건: ${badge["requirement"]}"),
          );
        },
      ),
    );
  }
}
