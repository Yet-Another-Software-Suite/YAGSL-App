import 'package:flutter/foundation.dart';

class LogStore extends ChangeNotifier {
  final List<String> _lines = [];

  List<String> get lines => List.unmodifiable(_lines);

  void append(String line) {
    _lines.add(line);
    notifyListeners();
  }

  void appendLines(Iterable<String> lines) {
    _lines.addAll(lines);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
