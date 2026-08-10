import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    var content = file.readAsStringSync();
    bool changed = false;
    
    final regex = RegExp(r'''import\s+['"]([^'"]+)['"](.*);''');
    
    content = content.replaceAllMapped(regex, (match) {
      final importPath = match.group(1)!;
      final rest = match.group(2)!;
      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
        return match.group(0)!;
      }
      
      // Manual path normalization since 'package:path' is missing
      final fileDir = file.parent.path.replaceAll('\\', '/');
      final dirParts = fileDir.split('/');
      final importParts = importPath.split('/');
      
      for (final part in importParts) {
        if (part == '..') {
          if (dirParts.isNotEmpty) dirParts.removeLast();
        } else if (part != '.') {
          dirParts.add(part);
        }
      }
      
      final resolvedPath = dirParts.join('/');
      
      final libIndex = dirParts.indexOf('lib');
      if (libIndex != -1) {
        final packagePath = dirParts.skip(libIndex + 1).join('/');
        changed = true;
        return "import 'package:pragatix/$packagePath'$rest;";
      }
      
      return match.group(0)!;
    });
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
