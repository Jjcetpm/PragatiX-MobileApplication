class Team {
  final int id;
  final String name;
  final int size;
  final String? captainId;
  final String? captainName;
  final String? viceCaptainId;
  final String? viceCaptainName;
  final int? assignmentId;
  final String? activityName;
  final bool? isAwarded;
  final bool canDelete;
  final String? departmentName;
  final String? academicYear;
  final String? yearName;
  final String? semesterName;
  final String? sectionName;
  final int currentStage;
  final List<dynamic>?
  members; // Will refine based on StudentResponse if needed

  Team({
    required this.id,
    required this.name,
    required this.size,
    this.captainId,
    this.captainName,
    this.viceCaptainId,
    this.viceCaptainName,
    this.assignmentId,
    this.activityName,
    this.isAwarded,
    this.canDelete = false,
    this.departmentName,
    this.academicYear,
    this.yearName,
    this.semesterName,
    this.sectionName,
    this.currentStage = 1,
    this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['teamId'] ?? json['id'],
      name: json['teamName'] ?? json['name'] ?? '',
      size: json['teamCapacity'] ?? json['size'] ?? 0,
      captainId: json['captainId'],
      captainName: json['captainName'],
      viceCaptainId: json['viceCaptainId'],
      viceCaptainName: json['viceCaptainName'],
      assignmentId: json['assignmentId'],
      activityName: json['assignmentName'] ?? json['activityName'],
      isAwarded: json['isAwarded'],
      canDelete: json['canDelete'] ?? false,
      departmentName: json['departmentName'],
      academicYear: json['academicYearName'] ?? json['academicYear'],
      yearName: json['yearName'] ?? json['year'],
      semesterName: json['semesterName'],
      sectionName: json['sectionName'],
      currentStage: json['currentStage'] ?? 1,
      members: json['teamMembers'] != null
          ? List<dynamic>.from(json['teamMembers'])
          : (json['members'] != null
                ? List<dynamic>.from(json['members'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'captainId': captainId,
      'captainName': captainName,
      'viceCaptainId': viceCaptainId,
      'viceCaptainName': viceCaptainName,
      'assignmentId': assignmentId,
      'activityName': activityName,
      'isAwarded': isAwarded,
      'departmentName': departmentName,
      'academicYear': academicYear,
      'year': yearName,
      'semesterName': semesterName,
      'sectionName': sectionName,
      'currentStage': currentStage,
      'members': members,
    };
  }
}
