import 'package:flutter/material.dart';

Widget buildProfileImage(String? imageUrl, {double radius = 50}) {
  return CircleAvatar(
    radius: radius,
    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
        ? NetworkImage(imageUrl) // ✅ 네트워크 이미지 사용
        : const AssetImage("assets/logo.jpg") as ImageProvider, // ✅ 기본 로고 사용
  );
}
