class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String status;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.status = "온라인",
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'status': status,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      nickname: map['nickname'],
      status: map['status'] ?? "온라인",
    );
  }
}
