import 'app_status.dart';

/// Reads a nullable string from a Supabase row.
String? _str(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  return value is String && value.isNotEmpty ? value : null;
}

/// A row of `public.profiles`, joined with its institute and wifaq names.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    this.fatherName,
    this.instituteId,
    this.instituteName,
    this.wifaqId,
    this.wifaqName,
    this.city,
    this.phone,
    this.email,
    this.stage,
    this.avatarPath,
    this.status = AppStatus.active,
    this.joinedOn,
  });

  /// Same value as `auth.users.id`.
  final String id;
  final String fullName;
  final String? fatherName;
  final String? instituteId;
  final String? instituteName;
  final String? wifaqId;
  final String? wifaqName;
  final String? city;
  final String? phone;
  final String? email;

  /// تربیتی مرحلہ
  final String? stage;

  /// Object path inside the avatars bucket, not a URL.
  final String? avatarPath;

  final AppStatus status;
  final DateTime? joinedOn;

  /// Builds from a PostgREST row. Nested selects arrive as maps, so the
  /// institute and wifaq names are read from those when present.
  factory AppUser.fromMap(Map<String, dynamic> row) {
    final Object? institute = row['institutes'];
    final Object? wifaq = row['wifaqs'];
    final Object? joined = row['joined_on'];

    return AppUser(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?)?.trim().isNotEmpty ?? false
          ? (row['full_name'] as String).trim()
          : '',
      fatherName: _str(row, 'father_name'),
      instituteId: _str(row, 'institute_id'),
      instituteName:
          institute is Map<String, dynamic> ? _str(institute, 'name') : null,
      wifaqId: _str(row, 'wifaq_id'),
      wifaqName: wifaq is Map<String, dynamic> ? _str(wifaq, 'name') : null,
      city: _str(row, 'city'),
      phone: _str(row, 'phone'),
      email: _str(row, 'email'),
      stage: _str(row, 'stage'),
      avatarPath: _str(row, 'avatar_path'),
      status: AppStatusX.fromDb(_str(row, 'status')),
      joinedOn: joined is String ? DateTime.tryParse(joined) : null,
    );
  }

  /// First letter of the name, used inside the avatar circle.
  String get avatarLabel => fullName.isEmpty ? '؟' : fullName.substring(0, 1);

  /// Institute and city as one Urdu line, skipping whichever is missing.
  String? get placeLine {
    final List<String> parts = <String>[
      ?instituteName,
      ?city,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }
}

/// A graduate as it appears in a mentor or administrator list.
class GraduateSummary {
  const GraduateSummary({
    required this.id,
    required this.name,
    this.instituteName,
    this.city,
    this.stage,
    this.status = AppStatus.active,
    this.completedSteps = 0,
    this.totalSteps = 0,
    this.lastActivity,
    this.email,
  });

  final String id;
  final String name;
  final String? instituteName;
  final String? city;
  final String? stage;
  final AppStatus status;

  /// Filled in by the administrator's lists, where an account created
  /// without a name would otherwise be impossible to tell apart.
  final String? email;

  /// Progress is computed from real activity rows, never stored.
  final int completedSteps;
  final int totalSteps;

  /// Urdu description of the most recent thing that happened.
  final String? lastActivity;

  double get progress => totalSteps == 0 ? 0 : completedSteps / totalSteps;

  String? get placeLine {
    final List<String> parts = <String>[
      ?instituteName,
      ?city,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String get avatarLabel => name.isEmpty ? '؟' : name.substring(0, 1);
}

/// A mentor as it appears in the administrator list.
class MentorSummary {
  const MentorSummary({
    required this.id,
    required this.name,
    this.instituteName,
    this.city,
    this.graduateCount = 0,
    this.pendingReviews = 0,
    this.status = AppStatus.active,
  });

  final String id;
  final String name;
  final String? instituteName;
  final String? city;
  final int graduateCount;
  final int pendingReviews;
  final AppStatus status;

  String get avatarLabel => name.isEmpty ? '؟' : name.substring(0, 1);

  String? get placeLine {
    final List<String> parts = <String>[
      ?instituteName,
      ?city,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }
}
