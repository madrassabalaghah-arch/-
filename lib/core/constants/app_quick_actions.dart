import 'package:flutter/material.dart';

import '../../shared/models/dashboard_items.dart';
import '../routing/app_routes.dart';
import 'app_strings.dart';

/// Dashboard shortcuts and management areas.
///
/// These are navigation configuration, not database records: the same six
/// tiles appear for every graduate. The brief explicitly allows navigation
/// configuration to remain a UI constant, so they are declared here rather
/// than fetched.
class AppQuickActions {
  const AppQuickActions._();

  static const List<QuickAction> graduate = <QuickAction>[
    QuickAction(
      title: AppStrings.profile,
      icon: Icons.person_outline,
      route: AppRoutes.graduateProfile,
    ),
    QuickAction(
      title: AppStrings.practicalActivities,
      icon: Icons.volunteer_activism_outlined,
      route: AppRoutes.graduateActivities,
    ),
    QuickAction(
      title: AppStrings.myReports,
      icon: Icons.description_outlined,
      route: AppRoutes.graduateReports,
    ),
    QuickAction(
      title: AppStrings.evidence,
      icon: Icons.folder_open_outlined,
      route: AppRoutes.graduateEvidence,
    ),
    QuickAction(
      title: AppStrings.evaluation,
      icon: Icons.fact_check_outlined,
      route: AppRoutes.graduateEvaluations,
    ),
    QuickAction(
      title: AppStrings.recognitions,
      icon: Icons.workspace_premium_outlined,
      route: AppRoutes.graduateRecognition,
      isGold: true,
    ),
  ];

  static const List<QuickAction> mentor = <QuickAction>[
    QuickAction(
      title: AppStrings.myGraduates,
      icon: Icons.groups_outlined,
      route: AppRoutes.mentorGraduates,
    ),
    QuickAction(
      title: AppStrings.pendingReviews,
      icon: Icons.pending_actions_outlined,
      route: AppRoutes.mentorReviews,
    ),
    QuickAction(
      title: AppStrings.completedReviews,
      icon: Icons.fact_check_outlined,
      route: AppRoutes.mentorEvaluations,
    ),
  ];

  static const List<ManagementArea> adminAreas = <ManagementArea>[
    ManagementArea(
      title: AppStrings.manageWorkshop,
      subtitle: 'ورکشاپ کے شرکاء، جن کو اکاؤنٹ بنانے کی اجازت ہے۔',
      icon: Icons.how_to_reg_outlined,
      route: AppRoutes.adminWorkshop,
    ),
    ManagementArea(
      title: AppStrings.graduateManagement,
      subtitle: 'اندراج، حیثیت اور تربیتی مراحل کا انتظام۔',
      icon: Icons.school_outlined,
      route: AppRoutes.adminGraduates,
    ),
    ManagementArea(
      title: AppStrings.mentorManagement,
      subtitle: 'مربیوں کی تفویض اور نگرانی۔',
      icon: Icons.supervisor_account_outlined,
      route: AppRoutes.adminMentors,
    ),
    ManagementArea(
      title: AppStrings.wifaqManagement,
      subtitle: 'وفاق اور منسلک اداروں کی فہرست۔',
      icon: Icons.account_balance_outlined,
      route: AppRoutes.adminWifaqs,
    ),
    ManagementArea(
      title: AppStrings.practicalActivities,
      subtitle: 'وہ فہرست جس میں سے فاضلہ / فاضل سرگرمی منتخب کرتے ہیں۔',
      icon: Icons.volunteer_activism_outlined,
      route: AppRoutes.adminActivities,
    ),
    ManagementArea(
      title: AppStrings.courses,
      subtitle: 'کورسز اور تربیتی نصاب۔',
      icon: Icons.menu_book_outlined,
      route: AppRoutes.adminCourses,
    ),
    ManagementArea(
      title: AppStrings.assignments,
      subtitle: 'فاضلہ / فاضل کو تفویض کردہ ذمہ داریاں۔',
      icon: Icons.assignment_ind_outlined,
      route: AppRoutes.adminAssignments,
    ),
    ManagementArea(
      title: AppStrings.allReports,
      subtitle: 'تمام کارگزاریوں کا مجموعی جائزہ۔',
      icon: Icons.description_outlined,
      route: AppRoutes.adminReports,
    ),
    ManagementArea(
      title: AppStrings.standards,
      subtitle: 'جائزے کے معیارات اور ان کا وزن۔',
      icon: Icons.rule_outlined,
      route: AppRoutes.adminStandards,
    ),
    ManagementArea(
      title: AppStrings.recognitions,
      subtitle: 'اعزازات اور حوصلہ افزائی کا نظام۔',
      icon: Icons.workspace_premium_outlined,
      route: AppRoutes.adminRecognition,
    ),
    ManagementArea(
      title: AppStrings.notifications,
      subtitle: 'اطلاعات اور اعلانات کا انتظام۔',
      icon: Icons.notifications_none_outlined,
      route: AppRoutes.adminNotifications,
    ),
  ];
}
