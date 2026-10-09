import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'\.withOpacity\(([^)]+)\)');
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        final newContent = content.replaceAllMapped(regex, (match) {
          final opacityValue = match.group(1);
          return '.withValues(alpha: $opacityValue)';
        });
        entity.writeAsStringSync(newContent);
        // ignore: avoid_print
        print('Updated ${entity.path}');
      }
    }
  }
}
