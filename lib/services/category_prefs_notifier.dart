import 'package:flutter/foundation.dart';

class CategoryPrefsNotifier extends ChangeNotifier {
  CategoryPrefsNotifier._();
  static final instance = CategoryPrefsNotifier._();

  List<String> _ids = [];
  List<String> get ids => _ids;

  void update(List<String> newIds) {
    _ids = List.unmodifiable(newIds);
    notifyListeners();
  }
}
