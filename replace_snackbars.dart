import 'dart:io';

void main() {
  final libDir = Directory('lib');
  
  // RegExp to find ScaffoldMessenger.of(context).showSnackBar(...)
  final pattern = RegExp(
    r"ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\s*\((.*?)\);",
    multiLine: true,
    dotAll: true,
  );

  final importStatement = "import 'package:mantri_app/core/utils/app_dialogs.dart';\n";

  for (final file in libDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      final newContent = content.replaceAllMapped(pattern, (match) {
        final inner = match.group(1)!;
        
        // Try to extract Text(...)
        String textArg = "'Success'";
        final textPattern = RegExp(r"Text\((.*?)\)", dotAll: true);
        final textMatch = textPattern.firstMatch(inner);
        if (textMatch != null) {
          textArg = textMatch.group(1)!;
        }

        final lowerText = textArg.toLowerCase();
        if (lowerText.contains('error') || lowerText.contains('fail') || lowerText.contains('not ')) {
          return "AppDialogs.showErrorDialog(context, userMessage: $textArg);";
        } else if (lowerText.contains('delete') || lowerText.contains('remove')) {
          return "AppDialogs.showWarningDialog(context, message: $textArg);";
        } else {
          return "AppDialogs.showSuccessDialog(context, message: $textArg);";
        }
      });

      if (newContent != content) {
        String finalContent = newContent;
        if (!finalContent.contains('app_dialogs.dart')) {
          final importPattern = RegExp(r"^import\s+['" + '"].*?[' + '"];', multiLine: true);
          final matches = importPattern.allMatches(finalContent);
          if (matches.isNotEmpty) {
            final lastMatch = matches.last;
            final insertPos = lastMatch.end;
            finalContent = finalContent.substring(0, insertPos) + '\n' + importStatement + finalContent.substring(insertPos);
          } else {
            finalContent = importStatement + finalContent;
          }
        }
        file.writeAsStringSync(finalContent);
        print("Updated: ${file.path}");
      }
    }
  }
}
