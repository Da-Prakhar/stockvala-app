class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String tier;
  final String kycStatus;   // 'pending' | 'verified' | 'rejected'
  final bool twoFAEnabled;
  final bool emailVerified;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.tier = 'Standard',
    this.kycStatus = 'pending',
    this.twoFAEnabled = false,
    this.emailVerified = false,
    required this.createdAt,
  });

  String get name => '$firstName $lastName'.trim();
  bool get kycVerified => kycStatus == 'verified';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase().isNotEmpty ? '$f$l'.toUpperCase() : 'U';
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // Unwrap {success, data: {...}} envelope if present
    final d = (j['data'] is Map) ? j['data'] as Map<String, dynamic> : j;
    return AppUser(
      id: d['id']?.toString() ?? '',
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? d['phoneNumber'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? d['avatar_url'] as String?,
      tier: d['tier'] as String? ?? 'Standard',
      kycStatus: d['kycStatus'] as String? ?? 'pending',
      twoFAEnabled: d['twoFactorEnabled'] as bool? ?? d['two_fa_enabled'] as bool? ?? false,
      emailVerified: d['emailVerified'] as bool? ?? false,
      createdAt: DateTime.tryParse(d['createdAt'] as String? ?? d['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'firstName': firstName, 'lastName': lastName,
    'email': email, 'phone': phone, 'avatarUrl': avatarUrl,
    'tier': tier, 'kycStatus': kycStatus,
    'twoFactorEnabled': twoFAEnabled, 'emailVerified': emailVerified,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final AppUser user;
  final bool requiresPin;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.requiresPin = false,
  });

  // API response: {"success": true, "data": {"user": {...}, "accessToken": "...", "refreshToken": "..."}}
  factory AuthResponse.fromJson(Map<String, dynamic> j) {
    final d = (j['data'] is Map) ? j['data'] as Map<String, dynamic> : j;
    return AuthResponse(
      accessToken: d['accessToken'] as String? ?? d['access_token'] as String? ?? '',
      refreshToken: d['refreshToken'] as String? ?? d['refresh_token'] as String? ?? '',
      user: AppUser.fromJson(d['user'] as Map<String, dynamic>? ?? {}),
      requiresPin: d['requiresPin'] as bool? ?? d['requires_pin'] as bool? ?? false,
    );
  }
}

class OtpVerifyRequest {
  final String target;
  final String otp;
  final String? purpose;

  const OtpVerifyRequest({required this.target, required this.otp, this.purpose});

  Map<String, dynamic> toJson() => {'target': target, 'otp': otp, if (purpose != null) 'purpose': purpose};
}
