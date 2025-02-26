import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String profileImageUrl;
  final String nickname;
  final String homeShop;
  final String dartBoard;
  final int rating;
  final VoidCallback onProfileImageTap;
  final VoidCallback onNicknameTap;
  final VoidCallback onHomeShopTap;
  final VoidCallback onDartBoardTap;
  final VoidCallback onRatingTap;

  const ProfileCard({
    Key? key,
    required this.profileImageUrl,
    required this.nickname,
    required this.homeShop,
    required this.dartBoard,
    required this.rating,
    required this.onProfileImageTap,
    required this.onNicknameTap,
    required this.onHomeShopTap,
    required this.onDartBoardTap,
    required this.onRatingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      color: Colors.grey[900], // ✅ 다크 테마 적용
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ 프로필 사진 (클릭 가능)
            GestureDetector(
              onTap: onProfileImageTap,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: (profileImageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 15),

            // ✅ 닉네임 (클릭 시 수정 페이지로 이동)
            GestureDetector(
              onTap: onNicknameTap,
              child: Text(
                nickname,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ 홈샵 (클릭 시 수정 가능)
            GestureDetector(
              onTap: onHomeShopTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, color: Colors.blueAccent),
                  const SizedBox(width: 5),
                  Text(
                    homeShop,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ✅ 다트보드 / 레이팅 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onDartBoardTap,
                  child: Row(
                    children: [
                      const Icon(Icons.sports, color: Colors.orangeAccent),
                      const SizedBox(width: 5),
                      Text(
                        dartBoard,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: onRatingTap,
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellowAccent),
                      const SizedBox(width: 5),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
