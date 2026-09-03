import '../../core/constants/app_strings.dart';
import 'app_status.dart';
import 'work_items.dart';

/// One row of the wifaq hierarchy, with real counts from the database.
///
/// A null [wifaqId] is not an error case — it is the bucket of institutes
/// and graduates that have not been attached to any board yet, and it must
/// stay visible so that gap is obvious to an administrator rather than
/// silently dropped from the list.
class WifaqDirectoryEntry {
  const WifaqDirectoryEntry({
    this.wifaqId,
    this.wifaqName,
    this.city,
    this.status = AppStatus.active,
    this.instituteCount = 0,
    this.graduateTotal = 0,
    this.maleCount = 0,
    this.femaleCount = 0,
    this.unknownGenderCount = 0,
  });

  final String? wifaqId;
  final String? wifaqName;
  final String? city;
  final AppStatus status;
  final int instituteCount;
  final int graduateTotal;
  final int maleCount;
  final int femaleCount;
  final int unknownGenderCount;

  bool get isUnassigned => wifaqId == null;
  String get displayName => wifaqName ?? AppStrings.unassignedWifaq;

  factory WifaqDirectoryEntry.fromMap(Map<String, dynamic> row) =>
      WifaqDirectoryEntry(
        wifaqId: nullableString(row, 'wifaq_id'),
        wifaqName: nullableString(row, 'wifaq_name'),
        city: nullableString(row, 'city'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
        instituteCount: intOr(row, 'institute_count'),
        graduateTotal: intOr(row, 'graduate_total'),
        maleCount: intOr(row, 'male_count'),
        femaleCount: intOr(row, 'female_count'),
        unknownGenderCount: intOr(row, 'unknown_gender_count'),
      );
}

/// One row of the institutes belonging to a single wifaq (or, when
/// [instituteId] is null, the graduates in that wifaq who named no
/// institute at all).
class InstituteDirectoryEntry {
  const InstituteDirectoryEntry({
    this.instituteId,
    this.instituteName,
    this.city,
    this.status = AppStatus.active,
    this.graduateTotal = 0,
    this.maleCount = 0,
    this.femaleCount = 0,
    this.unknownGenderCount = 0,
  });

  final String? instituteId;
  final String? instituteName;
  final String? city;
  final AppStatus status;
  final int graduateTotal;
  final int maleCount;
  final int femaleCount;
  final int unknownGenderCount;

  bool get isUnassigned => instituteId == null;
  String get displayName => instituteName ?? AppStrings.unassignedInstitute;

  factory InstituteDirectoryEntry.fromMap(Map<String, dynamic> row) =>
      InstituteDirectoryEntry(
        instituteId: nullableString(row, 'institute_id'),
        instituteName: nullableString(row, 'institute_name'),
        city: nullableString(row, 'city'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
        graduateTotal: intOr(row, 'graduate_total'),
        maleCount: intOr(row, 'male_count'),
        femaleCount: intOr(row, 'female_count'),
        unknownGenderCount: intOr(row, 'unknown_gender_count'),
      );
}
