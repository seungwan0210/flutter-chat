import 'package:flutter/material.dart';

class User {
  final String nickname;
  final String status;

  User({required this.nickname, required this.status});
}

class UserTile extends StatelessWidget {
  final User user;

  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.nickname[0]), // 닉네임 첫 글자 표시
      ),
      title: Text(user.nickname),
      subtitle: Text(user.status),
      onTap: () {
        // 프로필 페이지로 이동 가능
      },
    );
  }
}
