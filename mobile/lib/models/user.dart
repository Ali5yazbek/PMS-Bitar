// ─── User Model ───────────────────────────────────────────────────────────────

class User {
  final int id;
  final String name;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
}
