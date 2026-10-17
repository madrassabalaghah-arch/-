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

  // میری پروفائل and اہم لنکس are bottom-navigation destinations, so they are
  // deliberately absent here — a tile that duplicates the bar underneath it
  // is one more thing to read and no new way to get anywhere.
  static const List<QuickAction> graduate = <QuickAction>[
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

  /// The administrator's areas, grouped as the brief sets out. Every screen
  /// the flat list used to offer is still here, placed in the group it
  /// belongs to, and participant verification data sits apart from all of it.
  static const List<({String title, List<ManagementArea> areas})> adminGroups =
      <({String title, List<ManagementArea> areas})>[
    (
      title: AppStrings.groupManagement,
      areas: <ManagementArea>[
        ManagementArea(title: AppStrings.graduateManagement, subtitle: 'اندراج، حیثیت اور تفصیلات۔', icon: Icons.school_outlined, route: AppRoutes.adminGraduates),
        ManagementArea(title: AppStrings.mentorManagement, subtitle: 'مربیوں کی تفویض اور نگرانی۔', icon: Icons.supervisor_account_outlined, route: AppRoutes.adminMentors),
        ManagementArea(title: AppStrings.staffManagement, subtitle: 'نئے مربی یا منتظم کو دعوت دیں، منتظمین دیکھیں۔', icon: Icons.admin_panel_settings_outlined, route: AppRoutes.adminStaff),
        ManagementArea(title: AppStrings.communityBoard, subtitle: 'مشترکہ سرگرمیاں، عوامی تبصرے اور حوصلہ افزائی۔', icon: Icons.forum_outlined, route: AppRoutes.communityBoard),
        ManagementArea(title: AppStrings.wifaqManagement, subtitle: 'وفاق، ان کے ادارے اور فضلاء و فاضلات۔', icon: Icons.account_balance_outlined, route: AppRoutes.adminWifaqs),
        ManagementArea(title: AppStrings.allInstitutes, subtitle: 'تمام ادارے اور ان کے فضلاء و فاضلات۔', icon: Icons.location_city_outlined, route: AppRoutes.adminInstitutes),
        ManagementArea(title: AppStrings.courses, subtitle: 'کورسز اور تربیتی نصاب۔', icon: Icons.menu_book_outlined, route: AppRoutes.adminCourses),
      ],
    ),
    (
      title: AppStrings.groupKarGuzari,
      areas: <ManagementArea>[
        ManagementArea(title: AppStrings.allReports, subtitle: 'تمام کارگزاریاں۔', icon: Icons.description_outlined, route: AppRoutes.adminReports),
        ManagementArea(title: AppStrings.evidenceManagement, subtitle: 'جمع کردہ ثبوت اور ان کا جائزہ۔', icon: Icons.folder_open_outlined, route: AppRoutes.adminEvidence),
        ManagementArea(title: AppStrings.allReviews, subtitle: 'مربیوں کے لکھے ہوئے جائزے۔', icon: Icons.fact_check_outlined, route: AppRoutes.adminEvaluations),
        ManagementArea(title: AppStrings.statisticsReports, subtitle: 'کارگزاری کے اعداد و شمار۔', icon: Icons.insights_outlined, route: AppRoutes.adminStatistics),
        ManagementArea(title: AppStrings.assignments, subtitle: 'فضلاء و فاضلات کو تفویض کردہ ذمہ داریاں۔', icon: Icons.assignment_ind_outlined, route: AppRoutes.adminAssignments),
        ManagementArea(title: AppStrings.practicalActivities, subtitle: 'عملی سرگرمیوں کی فہرست۔', icon: Icons.volunteer_activism_outlined, route: AppRoutes.adminActivities),
      ],
    ),
    (
      title: AppStrings.groupSystem,
      areas: <ManagementArea>[
        ManagementArea(title: AppStrings.notifications, subtitle: 'اطلاعات اور اعلانات۔', icon: Icons.notifications_none_outlined, route: AppRoutes.adminNotifications),
        ManagementArea(title: AppStrings.recognitions, subtitle: 'اعزازات اور حوصلہ افزائی۔', icon: Icons.workspace_premium_outlined, route: AppRoutes.adminRecognition),
        ManagementArea(title: AppStrings.importantLinks, subtitle: 'ویڈیوز، فارم، ویب سائٹس اور رہنما مواد۔', icon: Icons.link_outlined, route: AppRoutes.adminLinks),
        ManagementArea(title: AppStrings.systemSettings, subtitle: 'کارگزاری کا وقفہ اور اعزازات کے اصول۔', icon: Icons.tune_outlined, route: AppRoutes.adminSettings),
      ],
    ),
    (
      title: AppStrings.groupBackend,
      areas: <ManagementArea>[
        ManagementArea(title: AppStrings.backendDataManagement, subtitle: 'کورس کے شرکاء کا تصدیقی ڈیٹا، فائل سے درآمد۔', icon: Icons.storage_outlined, route: AppRoutes.adminWorkshop),
      ],
    ),
  ];
}
