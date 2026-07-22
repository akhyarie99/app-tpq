class MasjidInfo {
  MasjidInfo({required this.id, required this.name, this.logo});

  final String id;
  final String name;
  final String? logo;

  factory MasjidInfo.fromJson(Map<String, dynamic> json) => MasjidInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
      );
}

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.masjid,
    this.avatar,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? avatar;
  final MasjidInfo masjid;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        avatar: json['avatar'] as String?,
        masjid: MasjidInfo.fromJson(json['masjid'] as Map<String, dynamic>),
      );

  bool get isUstadzOnly => role == 'ustadz';
}
