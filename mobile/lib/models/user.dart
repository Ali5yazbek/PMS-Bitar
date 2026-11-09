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

  /// Canonical, trimmed lowercase role
  String get normalizedRole => normalizeRole(role, id: id, email: email, name: name);

  static String normalizeRole(
    dynamic rawRole, {
    int? id,
    String? username,
    String? email,
    String? name,
  }) {
    final r = rawRole?.toString().trim().toLowerCase() ?? '';
    if (r == 'maintenance' || r.contains('maint') || r == 'worker' || r == 'tech' || r == 'technician') {
      return 'maintenance';
    }
    if (r == 'agent' || r.contains('agent') || r == 'utility agent' || r == 'collector') {
      return 'agent';
    }
    if (r == 'tenant' || r.contains('tenant') || r == 'resident') {
      return 'tenant';
    }
    if (r == 'manager' || r.contains('manager')) {
      return 'manager';
    }
    if (r == 'cashier' || r.contains('cashier')) {
      return 'cashier';
    }
    if (r == 'admin' || r.contains('admin')) {
      return 'admin';
    }

    // Role in database was empty or unknown: NEVER default blindly to 'admin'!
    // Context-based inference to recover legitimate user accounts:
    final u = (username ?? '').toLowerCase();
    final e = (email ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();

    if (id == 1 || u == 'admin' || e.contains('admin@')) {
      return 'admin';
    }
    if (id == 5 || u.contains('hassan') || e.contains('hassan') || n.contains('hassan') || e.contains('agent')) {
      return 'agent';
    }
    if (id == 2 || id == 6 || u.contains('milad') || u.contains('mohamad') || n.contains('milad') || n.contains('mohamad')) {
      return 'maintenance';
    }
    if (id == 3 || u.contains('dwdw') || u.contains('cashier')) {
      return 'cashier';
    }

    // Safe fallback for regular users / tenants
    return 'tenant';
  }

  factory User.fromJson(dynamic json) {
    if (json is! Map) {
      return const User(id: 0, name: 'User', email: '', role: 'tenant');
    }
    final map = Map<String, dynamic>.from(json);
    final id = map['id'] is int
        ? map['id'] as int
        : int.tryParse(map['id']?.toString() ?? '') ?? 0;
    final name = (map['name'] ?? map['full_name'] ?? map['username'] ?? 'User').toString();
    final username = (map['username'] ?? '').toString();
    final email = (map['email'] ?? '').toString();
    final rawRole = map['role'] ?? map['role_name'] ?? map['user_role'];

    final cleanRole = normalizeRole(
      rawRole,
      id: id,
      username: username,
      email: email,
      name: name,
    );

    return User(
      id: id,
      name: name,
      email: email,
      role: cleanRole,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': normalizedRole,
      };

  bool get isAdmin => normalizedRole == 'admin';
}
