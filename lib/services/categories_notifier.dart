import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import 'api_service.dart';

class CategoriesNotifier extends ChangeNotifier {
  CategoriesNotifier._();
  static final instance = CategoriesNotifier._();

  List<Category> _categories = [];
  bool _loaded = false;

  List<Category> get categories => _categories;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      _categories = await ApiService.getCategories();
      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  void update(List<Category> cats) {
    _categories = List.unmodifiable(cats);
    _loaded = true;
    notifyListeners();
  }
}
