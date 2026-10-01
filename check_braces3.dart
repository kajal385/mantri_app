import 'dart:io';

void main() {
  final content = File('lib/features/news/presentation/screens/news_screen.dart').readAsStringSync();
  List<int> stack = [];
  int line = 1;
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '\n') line++;
    else if (content[i] == '{') {
      stack.add(line);
      // print('Open { at line $line, stack size ${stack.length}');
    }
    else if (content[i] == '}') {
      if (stack.isNotEmpty) {
        int openedAt = stack.removeLast();
        // print('Close } at line $line matching line $openedAt, stack size ${stack.length}');
      }
    }
  }
  print('Unclosed { opened at lines: $stack');
}
