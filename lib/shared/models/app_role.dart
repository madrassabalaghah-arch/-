import 'package:flutter/material.dart';

/// The three real roles, mirroring the `public.app_role` enum in Postgres.
///
/// [id] is the exact database value. It is code, never shown to the user;
/// screens always display [urduTitle].
enum AppRole {
  graduate(
    id: 'graduate',
    urduTitle: 'فاضلہ / فاضل',
    urduDescription:
        'اپنی تربیت، عملی سرگرمیوں، کارگزاری اور پیش رفت کا جائزہ لیں۔',
    icon: Icons.school_outlined,
  ),
  mentor(
    id: 'mentor',
    urduTitle: 'مربی',
    urduDescription:
        'اپنے زیرِ رہنمائی فاضلہ / فاضل کی کارگزاریوں اور پیش رفت کا جائزہ لیں۔',
    icon: Icons.supervisor_account_outlined,
  ),
  admin(
    id: 'admin',
    urduTitle: 'منتظم',
    urduDescription: 'فاضلہ / فاضل، مربیوں، کارگزاریوں اور نظام کا انتظام کریں۔',
    icon: Icons.admin_panel_settings_outlined,
  );

  const AppRole({
    required this.id,
    required this.urduTitle,
    required this.urduDescription,
    required this.icon,
  });

  /// The value stored in `public.user_roles.role`.
  final String id;

  /// Urdu label shown in the interface.
  final String urduTitle;

  /// Short Urdu explanation of what the role can do.
  final String urduDescription;

  final IconData icon;

  /// Urdu title of this role's dashboard.
  String get dashboardTitle => '$urduTitle ڈیش بورڈ';

  /// Resolves a database value. Returns null for anything unrecognised
  /// rather than guessing, so an unexpected value fails closed.
  static AppRole? fromId(String? value) {
    if (value == null) {
      return null;
    }
    for (final AppRole role in AppRole.values) {
      if (role.id == value) {
        return role;
      }
    }
    return null;
  }

  /// Picks the strongest role when a user holds more than one. A person who
  /// is both a mentor and an administrator lands on the administrator area.
  static AppRole? highest(Iterable<AppRole> roles) {
    if (roles.contains(AppRole.admin)) {
      return AppRole.admin;
    }
    if (roles.contains(AppRole.mentor)) {
      return AppRole.mentor;
    }
    if (roles.contains(AppRole.graduate)) {
      return AppRole.graduate;
    }
    return null;
  }
}
