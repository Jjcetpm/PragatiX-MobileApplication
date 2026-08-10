# Project Overview

## 1. Complete Folder Tree

Below is the complete reverse-engineered folder structure of the Flutter frontend project, showing every folder and every Dart file without skipping or collapsing.

```text
lib/
├── main.dart
├── admin/
│   └── activity/
│       ├── models/
│       │   ├── activity_model.dart
│       │   ├── execution_student_model.dart
│       │   └── my_activity_model.dart
│       ├── pages/
│       │   ├── activity_details_page.dart
│       │   ├── activity_execution_page.dart
│       │   ├── activity_execution_page_v2.dart
│       │   ├── activity_list_page.dart
│       │   ├── admin_activity_detail_page.dart
│       │   ├── assign_faculty_page.dart
│       │   ├── create_activity_page.dart
│       │   ├── create_group_page.dart
│       │   ├── edit_activity_page.dart
│       │   ├── group_activity_dept_page.dart
│       │   ├── group_activity_execution_page.dart
│       │   ├── group_activity_sec_page.dart
│       │   ├── group_activity_year_page.dart
│       │   └── group_details_page.dart
│       ├── providers/
│       │   └── activity_provider.dart
│       ├── repository/
│       │   └── activity_repository.dart
│       ├── services/
│       │   └── activity_service.dart
│       ├── utils/
│       │   ├── constants.dart
│       │   └── validators.dart
│       └── widgets/
│           ├── activity_card.dart
│           ├── activity_form.dart
│           ├── activity_section.dart
│           ├── cap_selector.dart
│           ├── evidence_selector.dart
│           ├── frequency_selector.dart
│           ├── owner_selector.dart
│           ├── sticky_bottom_buttons.dart
│           ├── type_selector.dart
│           └── xp_selector.dart
├── core/
│   └── config/
│       └── api_config.dart
├── models/
│   ├── student.dart
│   └── team.dart
├── providers/
│   ├── badge_provider.dart
│   └── xp_provider.dart
├── repositories/
│   └── badge_repository.dart
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── create_stage_page.dart
│   │   ├── edit_stage_page.dart
│   │   ├── stage_details_page.dart
│   │   └── tabs/
│   │       ├── activity_tab.dart
│   │       ├── departments_tab.dart
│   │       ├── overview_tab.dart
│   │       ├── profile_tab.dart
│   │       ├── students_tab.dart
│   │       └── teachers_tab.dart
│   ├── captain/
│   │   ├── captain_dashboard_page.dart
│   │   └── tabs/
│   │       ├── activities_tab.dart
│   │       ├── captain_group_tab.dart
│   │       ├── dashboard_tab.dart
│   │       ├── leaderboard_tab.dart
│   │       ├── point_review_tab.dart
│   │       └── profile_tab.dart
│   ├── login/
│   │   └── login_page.dart
│   ├── student/
│   │   ├── student_dashboard_page.dart
│   │   └── tabs/
│   │       ├── activities_tab.dart
│   │       ├── dashboard_tab.dart
│   │       ├── leaderboard_tab.dart
│   │       ├── levels_badges_tab.dart
│   │       ├── point_review_tab.dart
│   │       └── profile_tab.dart
│   └── teacher/
│       ├── teacher_dashboard.dart
│       ├── teacher_student_detail.dart
│       └── tabs/
│           ├── activity_tab.dart
│           ├── badge_claims_tab.dart
│           ├── hod_performance_tab.dart
│           ├── leaderboard_tab.dart
│           ├── performance_activities_tab.dart
│           ├── profile_tab.dart
│           ├── removal_requests_tab.dart
│           ├── students_tab.dart
│           └── teacher_group_management_tab.dart
└── services/
    ├── group_activity_service.dart
    └── student_service.dart
```

---

## 2. File Inventory

| No | File Name | Path | Module | Type |
|----|-----------|------|--------|------|
| 1 | `main.dart` | `lib/main.dart` | Core | Config |
| 2 | `activity_model.dart` | `lib/admin/activity/models/activity_model.dart` | Admin/Activity | Model |
| 3 | `execution_student_model.dart` | `lib/admin/activity/models/execution_student_model.dart` | Admin/Activity | Model |
| 4 | `my_activity_model.dart` | `lib/admin/activity/models/my_activity_model.dart` | Admin/Activity | Model |
| 5 | `activity_details_page.dart` | `lib/admin/activity/pages/activity_details_page.dart` | Admin/Activity | Page |
| 6 | `activity_execution_page.dart` | `lib/admin/activity/pages/activity_execution_page.dart` | Admin/Activity | Page |
| 7 | `activity_execution_page_v2.dart` | `lib/admin/activity/pages/activity_execution_page_v2.dart` | Admin/Activity | Page |
| 8 | `activity_list_page.dart` | `lib/admin/activity/pages/activity_list_page.dart` | Admin/Activity | Page |
| 9 | `admin_activity_detail_page.dart` | `lib/admin/activity/pages/admin_activity_detail_page.dart` | Admin/Activity | Page |
| 10 | `assign_faculty_page.dart` | `lib/admin/activity/pages/assign_faculty_page.dart` | Admin/Activity | Page |
| 11 | `create_activity_page.dart` | `lib/admin/activity/pages/create_activity_page.dart` | Admin/Activity | Page |
| 12 | `create_group_page.dart` | `lib/admin/activity/pages/create_group_page.dart` | Admin/Activity | Page |
| 13 | `edit_activity_page.dart` | `lib/admin/activity/pages/edit_activity_page.dart` | Admin/Activity | Page |
| 14 | `group_activity_dept_page.dart` | `lib/admin/activity/pages/group_activity_dept_page.dart` | Admin/Activity | Page |
| 15 | `group_activity_execution_page.dart` | `lib/admin/activity/pages/group_activity_execution_page.dart` | Admin/Activity | Page |
| 16 | `group_activity_sec_page.dart` | `lib/admin/activity/pages/group_activity_sec_page.dart` | Admin/Activity | Page |
| 17 | `group_activity_year_page.dart` | `lib/admin/activity/pages/group_activity_year_page.dart` | Admin/Activity | Page |
| 18 | `group_details_page.dart` | `lib/admin/activity/pages/group_details_page.dart` | Admin/Activity | Page |
| 19 | `activity_provider.dart` | `lib/admin/activity/providers/activity_provider.dart` | Admin/Activity | Provider |
| 20 | `activity_repository.dart` | `lib/admin/activity/repository/activity_repository.dart` | Admin/Activity | Repository |
| 21 | `activity_service.dart` | `lib/admin/activity/services/activity_service.dart` | Admin/Activity | Service |
| 22 | `constants.dart` | `lib/admin/activity/utils/constants.dart` | Admin/Activity | Constant |
| 23 | `validators.dart` | `lib/admin/activity/utils/validators.dart` | Admin/Activity | Helper |
| 24 | `activity_card.dart` | `lib/admin/activity/widgets/activity_card.dart` | Admin/Activity | Widget |
| 25 | `activity_form.dart` | `lib/admin/activity/widgets/activity_form.dart` | Admin/Activity | Widget |
| 26 | `activity_section.dart` | `lib/admin/activity/widgets/activity_section.dart` | Admin/Activity | Widget |
| 27 | `cap_selector.dart` | `lib/admin/activity/widgets/cap_selector.dart` | Admin/Activity | Widget |
| 28 | `evidence_selector.dart` | `lib/admin/activity/widgets/evidence_selector.dart` | Admin/Activity | Widget |
| 29 | `frequency_selector.dart` | `lib/admin/activity/widgets/frequency_selector.dart` | Admin/Activity | Widget |
| 30 | `owner_selector.dart` | `lib/admin/activity/widgets/owner_selector.dart` | Admin/Activity | Widget |
| 31 | `sticky_bottom_buttons.dart` | `lib/admin/activity/widgets/sticky_bottom_buttons.dart` | Admin/Activity | Widget |
| 32 | `type_selector.dart` | `lib/admin/activity/widgets/type_selector.dart` | Admin/Activity | Widget |
| 33 | `xp_selector.dart` | `lib/admin/activity/widgets/xp_selector.dart` | Admin/Activity | Widget |
| 34 | `api_config.dart` | `lib/core/config/api_config.dart` | Core | Config |
| 35 | `student.dart` | `lib/models/student.dart` | Shared | Model |
| 36 | `team.dart` | `lib/models/team.dart` | Shared | Model |
| 37 | `badge_provider.dart` | `lib/providers/badge_provider.dart` | Shared | Provider |
| 38 | `xp_provider.dart` | `lib/providers/xp_provider.dart` | Shared | Provider |
| 39 | `badge_repository.dart` | `lib/repositories/badge_repository.dart` | Shared | Repository |
| 40 | `admin_dashboard.dart` | `lib/screens/admin/admin_dashboard.dart` | Admin | Page |
| 41 | `create_stage_page.dart` | `lib/screens/admin/create_stage_page.dart` | Admin | Page |
| 42 | `edit_stage_page.dart` | `lib/screens/admin/edit_stage_page.dart` | Admin | Page |
| 43 | `stage_details_page.dart` | `lib/screens/admin/stage_details_page.dart` | Admin | Page |
| 44 | `activity_tab.dart` | `lib/screens/admin/tabs/activity_tab.dart` | Admin | Page |
| 45 | `departments_tab.dart` | `lib/screens/admin/tabs/departments_tab.dart` | Admin | Page |
| 46 | `overview_tab.dart` | `lib/screens/admin/tabs/overview_tab.dart` | Admin | Page |
| 47 | `profile_tab.dart` | `lib/screens/admin/tabs/profile_tab.dart` | Admin | Page |
| 48 | `students_tab.dart` | `lib/screens/admin/tabs/students_tab.dart` | Admin | Page |
| 49 | `teachers_tab.dart` | `lib/screens/admin/tabs/teachers_tab.dart` | Admin | Page |
| 50 | `captain_dashboard_page.dart` | `lib/screens/captain/captain_dashboard_page.dart` | Captain | Page |
| 51 | `activities_tab.dart` | `lib/screens/captain/tabs/activities_tab.dart` | Captain | Page |
| 52 | `captain_group_tab.dart` | `lib/screens/captain/tabs/captain_group_tab.dart` | Captain | Page |
| 53 | `dashboard_tab.dart` | `lib/screens/captain/tabs/dashboard_tab.dart` | Captain | Page |
| 54 | `leaderboard_tab.dart` | `lib/screens/captain/tabs/leaderboard_tab.dart` | Captain | Page |
| 55 | `point_review_tab.dart` | `lib/screens/captain/tabs/point_review_tab.dart` | Captain | Page |
| 56 | `profile_tab.dart` | `lib/screens/captain/tabs/profile_tab.dart` | Captain | Page |
| 57 | `login_page.dart` | `lib/screens/login/login_page.dart` | Auth | Page |
| 58 | `student_dashboard_page.dart` | `lib/screens/student/student_dashboard_page.dart` | Student | Page |
| 59 | `activities_tab.dart` | `lib/screens/student/tabs/activities_tab.dart` | Student | Page |
| 60 | `dashboard_tab.dart` | `lib/screens/student/tabs/dashboard_tab.dart` | Student | Page |
| 61 | `leaderboard_tab.dart` | `lib/screens/student/tabs/leaderboard_tab.dart` | Student | Page |
| 62 | `levels_badges_tab.dart` | `lib/screens/student/tabs/levels_badges_tab.dart` | Student | Page |
| 63 | `point_review_tab.dart` | `lib/screens/student/tabs/point_review_tab.dart` | Student | Page |
| 64 | `profile_tab.dart` | `lib/screens/student/tabs/profile_tab.dart` | Student | Page |
| 65 | `teacher_dashboard.dart` | `lib/screens/teacher/teacher_dashboard.dart` | Teacher | Page |
| 66 | `teacher_student_detail.dart` | `lib/screens/teacher/teacher_student_detail.dart` | Teacher | Page |
| 67 | `activity_tab.dart` | `lib/screens/teacher/tabs/activity_tab.dart` | Teacher | Page |
| 68 | `badge_claims_tab.dart` | `lib/screens/teacher/tabs/badge_claims_tab.dart` | Teacher | Page |
| 69 | `hod_performance_tab.dart` | `lib/screens/teacher/tabs/hod_performance_tab.dart` | Teacher | Page |
| 70 | `leaderboard_tab.dart` | `lib/screens/teacher/tabs/leaderboard_tab.dart` | Teacher | Page |
| 71 | `performance_activities_tab.dart` | `lib/screens/teacher/tabs/performance_activities_tab.dart` | Teacher | Page |
| 72 | `profile_tab.dart` | `lib/screens/teacher/tabs/profile_tab.dart` | Teacher | Page |
| 73 | `removal_requests_tab.dart` | `lib/screens/teacher/tabs/removal_requests_tab.dart` | Teacher | Page |
| 74 | `students_tab.dart` | `lib/screens/teacher/tabs/students_tab.dart` | Teacher | Page |
| 75 | `teacher_group_management_tab.dart` | `lib/screens/teacher/tabs/teacher_group_management_tab.dart` | Teacher | Page |
| 76 | `group_activity_service.dart` | `lib/services/group_activity_service.dart` | Shared | Service |
| 77 | `student_service.dart` | `lib/services/student_service.dart` | Shared | Service |
