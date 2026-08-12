import 'dart:io';

void main() async {
  final file = File('lib/features/teacher/pages/teacher_dashboard.dart');
  String content = await file.readAsString();
  
  content = content.replaceFirst(
    "        if (_isHod) const HodPerformanceTab(),\r\n",
    ""
  );
  content = content.replaceFirst(
    "        if (_isHod) const HodPerformanceTab(),\n",
    ""
  );
  
  final tabRegExp = RegExp(r"\s*if \(_isHod\)\s*const BottomNavigationBarItem\(\s*icon: Icon\(Icons\.analytics_outlined\),\s*label: 'HOD Report',\s*\),\r?\n?");
  content = content.replaceFirst(tabRegExp, "\n");
  
  await file.writeAsString(content);
  print('Updated teacher_dashboard.dart');
}
