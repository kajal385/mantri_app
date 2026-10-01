import 'dart:io';

void main() {
  final content = File('lib/features/news/presentation/screens/news_screen.dart').readAsStringSync();
  List<int> stack = [];
  int line = 1;
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '\n') line++;
    else if (content[i] == '{') stack.add(line);
    else if (content[i] == '}') {
      if (stack.isEmpty) {
        print('Extra } at line $line');
        return;
      }
      stack.removeLast();
    }
  }
  print('Unclosed { opened at lines: $stack');
}
