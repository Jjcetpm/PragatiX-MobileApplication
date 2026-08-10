import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/pages/teacher_stage_list_page.dart';

class ActivityTab extends StatelessWidget {
  final List<String> subRoles;

  const ActivityTab({super.key, this.subRoles = const []});

  @override
  Widget build(BuildContext context) {
    return TeacherStageListPage(subRoles: subRoles);
  }
}
