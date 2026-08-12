import 'dart:io';

void main() async {
  // 1. Profile Page edit
  final profileFile = File('lib/features/profile/pages/profile_page.dart');
  String profileContent = await profileFile.readAsString();
  
  profileContent = profileContent.replaceAll(
    "            if (_profile!.teacherDetails != null) ...[\n              _buildTeacherCard(),\n              const SizedBox(height: 16),\n            ],",
    "// Teacher Information section removed based on user request."
  );
  profileContent = profileContent.replaceAll(
    "            if (_profile!.teacherDetails != null) ...[\r\n              _buildTeacherCard(),\r\n              const SizedBox(height: 16),\r\n            ],",
    "// Teacher Information section removed based on user request."
  );
  
  await profileFile.writeAsString(profileContent);
  print('Updated profile_page.dart');

  // 2. Teacher Stage List Page edit
  final stageFile = File('lib/features/teacher/pages/teacher_stage_list_page.dart');
  String stageContent = await stageFile.readAsString();
  
  // Replace _isCc block to include _isHod
  final isCcRegExp = RegExp(r"bool get _isCc => widget\.subRoles\.any\([\s\S]*?\);");
  if (isCcRegExp.hasMatch(stageContent) && !stageContent.contains("bool get _isHod")) {
    final match = isCcRegExp.firstMatch(stageContent)!.group(0)!;
    stageContent = stageContent.replaceFirst(match, "bool get _isHod => widget.subRoles.contains('HOD') || widget.subRoles.contains('ROLE_HOD');\n\n  $match");
  }

  // Replace Actions
  final actionsRegExp = RegExp(r"if \(_isCc\) \.\.\.\[([\s\S]*?)\]\,");
  if (actionsRegExp.hasMatch(stageContent)) {
    final newActions = '''
          if (_isCc)
            IconButton(
              icon: Badge(
                isLabelVisible: _pendingBadgeRequests > 0,
                label: Text(
                  _pendingBadgeRequests.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
              ),
              tooltip: 'Badge Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CCBadgeRequestsPage(),
                  ),
                ).then((_) => _fetchPendingBadges());
              },
            ),
          if (_isCc || _isHod)
            IconButton(
              icon: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
              ),
              tooltip: 'Students Directory',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentsTab(subRoles: widget.subRoles),
                  ),
                );
              },
            ),''';
    // Removed the `+ ','` at the end which caused `,,\n`. The regex matches `] ,`, but `newActions` already ends with `),`. We do need the comma.
    // Wait, the original regex matches: `if (_isCc) ...[ ... ],`
    // My newActions ends with `),`. If I just replace the match with newActions, it will end with `),`. It is valid dart syntax since the next item is `Consumer<PenaltyProvider>(...)`.
    stageContent = stageContent.replaceFirst(actionsRegExp.firstMatch(stageContent)!.group(0)!, newActions);
  }
  
  await stageFile.writeAsString(stageContent);
  print('Updated teacher_stage_list_page.dart');
}
