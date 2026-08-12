import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int replacedCount = 0;

  for (final file in files) {
    if (file.path.contains('pragatix_loader.dart')) continue;

    String content = await file.readAsString();
    bool modified = false;

    // We want to replace CircularProgressIndicator() and CircularProgressIndicator(color: ...)
    // with const PragatiXLoader() or PragatiXLoader() if it's inside const Center.
    // To be safe, we will just use a regex: CircularProgressIndicator\([^)]*\) -> PragatiXLoader()
    
    // Check if file contains CircularProgressIndicator
    if (content.contains('CircularProgressIndicator')) {
      // Find and replace. Note that if it was 'const CircularProgressIndicator()',
      // 'const PragatiXLoader()' is fine if PragatiXLoader has const constructor.
      // Wait, PragatiXLoader has a const constructor, BUT the import is needed.
      
      // Let's replace `const CircularProgressIndicator(...)` with `const PragatiXLoader()`
      // And `CircularProgressIndicator(...)` with `const PragatiXLoader()` (wait, if there's no const, adding const is fine if PragatiXLoader constructor is const, but it might already have const before it).
      
      content = content.replaceAll(RegExp(r'CircularProgressIndicator\([^)]*\)'), 'PragatiXLoader()');
      
      // Now add import if not present
      if (!content.contains('pragatix_loader.dart')) {
        // Insert after the first import
        final importIndex = content.indexOf('import ');
        if (importIndex != -1) {
          final endOfLine = content.indexOf('\n', importIndex);
          content = content.substring(0, endOfLine + 1) + 
                    "import 'package:pragatix/core/widgets/pragatix_loader.dart';\n" + 
                    content.substring(endOfLine + 1);
        } else {
          content = "import 'package:pragatix/core/widgets/pragatix_loader.dart';\n" + content;
        }
      }
      
      modified = true;
    }

    if (modified) {
      await file.writeAsString(content);
      replacedCount++;
      print('Updated: ${file.path}');
    }
  }

  print('Total files updated: $replacedCount');
}
