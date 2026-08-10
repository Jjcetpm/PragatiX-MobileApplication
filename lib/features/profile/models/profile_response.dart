class ProfileResponse {
  final int id;
  final String fullName;
  final String username;
  final String? email;
  final String? phone;
  final String role;
  final String? department;
  final String? accountStatus;
  final DateTime? createdDate;
  final DateTime? lastUpdated;

  final SuperAdminDetails? superAdminDetails;
  final AdminDetails? adminDetails;
  final TeacherDetails? teacherDetails;
  final StudentDetails? studentDetails;
  final CcDetails? ccDetails;
  final HodDetails? hodDetails;

  ProfileResponse({
    required this.id,
    required this.fullName,
    required this.username,
    this.email,
    this.phone,
    required this.role,
    this.department,
    this.accountStatus,
    this.createdDate,
    this.lastUpdated,
    this.superAdminDetails,
    this.adminDetails,
    this.teacherDetails,
    this.studentDetails,
    this.ccDetails,
    this.hodDetails,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? '',
      department: json['department'],
      accountStatus: json['accountStatus'],
      createdDate: json['createdDate'] != null ? DateTime.tryParse(json['createdDate']) : null,
      lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated']) : null,
      superAdminDetails: json['superAdminDetails'] != null ? SuperAdminDetails.fromJson(json['superAdminDetails']) : null,
      adminDetails: json['adminDetails'] != null ? AdminDetails.fromJson(json['adminDetails']) : null,
      teacherDetails: json['teacherDetails'] != null ? TeacherDetails.fromJson(json['teacherDetails']) : null,
      studentDetails: json['studentDetails'] != null ? StudentDetails.fromJson(json['studentDetails']) : null,
      ccDetails: json['ccDetails'] != null ? CcDetails.fromJson(json['ccDetails']) : null,
      hodDetails: json['hodDetails'] != null ? HodDetails.fromJson(json['hodDetails']) : null,
    );
  }
}

class SuperAdminDetails {
  final int totalDepartments;
  final int totalStudents;
  final int totalTeachers;
  final int totalStaff;
  final int totalAdmins;
  final int totalActivities;
  final int totalStages;
  final List<String> permissions;

  SuperAdminDetails.fromJson(Map<String, dynamic> json)
      : totalDepartments = json['totalDepartments'] ?? 0,
        totalStudents = json['totalStudents'] ?? 0,
        totalTeachers = json['totalTeachers'] ?? 0,
        totalStaff = json['totalStaff'] ?? 0,
        totalAdmins = json['totalAdmins'] ?? 0,
        totalActivities = json['totalActivities'] ?? 0,
        totalStages = json['totalStages'] ?? 0,
        permissions = List<String>.from(json['permissions'] ?? []);
}

class AdminDetails {
  final String? academicYear;
  final int totalStudentsInYear;
  final int totalGroups;
  final int totalActivities;
  final int totalStages;
  final List<String> permissions;

  AdminDetails.fromJson(Map<String, dynamic> json)
      : academicYear = json['academicYear'],
        totalStudentsInYear = json['totalStudentsInYear'] ?? 0,
        totalGroups = json['totalGroups'] ?? 0,
        totalActivities = json['totalActivities'] ?? 0,
        totalStages = json['totalStages'] ?? 0,
        permissions = List<String>.from(json['permissions'] ?? []);
}

class TeacherDetails {
  final String? employeeId;
  final int totalStudents;
  final int totalActivities;
  final int totalSections;
  final int attendanceTakenCount;
  final List<String> subjectsHandling;
  final List<String> permissions;

  TeacherDetails.fromJson(Map<String, dynamic> json)
      : employeeId = json['employeeId'],
        totalStudents = json['totalStudents'] ?? 0,
        totalActivities = json['totalActivities'] ?? 0,
        totalSections = json['totalSections'] ?? 0,
        attendanceTakenCount = json['attendanceTakenCount'] ?? 0,
        subjectsHandling = List<String>.from(json['subjectsHandling'] ?? []),
        permissions = List<String>.from(json['permissions'] ?? []);
}

class StudentDetails {
  final String? registerNumber;
  final String? rollNumber;
  final String? academicYear;
  final String? section;
  final String? semester;
  final String? batch;
  final int currentXp;
  final String? currentStage;
  final String? currentLevel;
  final int rank;
  final double attendancePercentage;
  final String? teamName;
  final bool isCaptain;
  final bool isViceCaptain;
  final int teamMembersCount;
  final int teamXp;
  final int teamRank;
  final List<String> permissions;

  StudentDetails.fromJson(Map<String, dynamic> json)
      : registerNumber = json['registerNumber'],
        rollNumber = json['rollNumber'],
        academicYear = json['academicYear'],
        section = json['section'],
        semester = json['semester'],
        batch = json['batch'],
        currentXp = json['currentXp'] ?? 0,
        currentStage = json['currentStage'],
        currentLevel = json['currentLevel'],
        rank = json['rank'] ?? 0,
        attendancePercentage = (json['attendancePercentage'] ?? 100.0).toDouble(),
        teamName = json['teamName'],
        isCaptain = json['isCaptain'] ?? false,
        isViceCaptain = json['isViceCaptain'] ?? false,
        teamMembersCount = json['teamMembersCount'] ?? 0,
        teamXp = json['teamXp'] ?? 0,
        teamRank = json['teamRank'] ?? 0,
        permissions = List<String>.from(json['permissions'] ?? []);
}

class CcDetails {
  final String? section;
  final String? academicYear;
  final int totalStudents;
  final int totalActivities;
  final List<String> permissions;

  CcDetails.fromJson(Map<String, dynamic> json)
      : section = json['section'],
        academicYear = json['academicYear'],
        totalStudents = json['totalStudents'] ?? 0,
        totalActivities = json['totalActivities'] ?? 0,
        permissions = List<String>.from(json['permissions'] ?? []);
}

class HodDetails {
  final int totalFaculty;
  final int totalStudents;
  final int totalSections;
  final int totalSubjects;
  final List<String> permissions;

  HodDetails.fromJson(Map<String, dynamic> json)
      : totalFaculty = json['totalFaculty'] ?? 0,
        totalStudents = json['totalStudents'] ?? 0,
        totalSections = json['totalSections'] ?? 0,
        totalSubjects = json['totalSubjects'] ?? 0,
        permissions = List<String>.from(json['permissions'] ?? []);
}
