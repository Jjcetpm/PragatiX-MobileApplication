import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  int replacedCount = 0;
  
  for (final file in files) {
    if (file.path.contains('pragatix_loader.dart')) continue;
    
    String content = await file.readAsString();
    bool modified = false;
    
    // Safely replace exact known patterns
    final patterns = [
      'CircularProgressIndicator()',
      'CircularProgressIndicator(strokeWidth: 2.5)',
      'CircularProgressIndicator(color: Color(0xFF11998e))',
      'CircularProgressIndicator(color: Color(0xFF11998E))',
      'CircularProgressIndicator(color: Color(0xFF38BDF8))',
      'CircularProgressIndicator(color: primaryColor)',
      'CircularProgressIndicator(color: _tealPrimary)',
    ];

    for (final pattern in patterns) {
      if (content.contains(pattern)) {
        content = content.replaceAll(pattern, 'PragatiXLoader()');
        modified = true;
      }
    }

    if (modified) {
      if (!content.contains('pragatix_loader.dart')) {
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
      await file.writeAsString(content);
      replacedCount++;
      print('Updated: ${file.path}');
    }
  }
  
  print('Total files updated safely: $replacedCount');
}
