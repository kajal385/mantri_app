import 'dart:io';

void main() {
  final content = File('lib/features/news/presentation/screens/news_screen.dart').readAsStringSync();
  int count = 0;
  int line = 1;
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '\n') line++;
    else if (content[i] == '{') count++;
    else if (content[i] == '}') {
      count--;
      if (count < 0) {
        print('Extra } at line $line');
        return;
      }
    }
  }
  print('Final count (unclosed {): $count');
}
