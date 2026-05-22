import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class CategoriesProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Map<String, dynamic>> _trending = [];
  bool _loading = false;

  List<Category> get categories => _categories;
  List<Map<String, dynamic>> get trending => _trending;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SupabaseService.getCategories(),
        SupabaseService.getTrendingHashtags(),
      ]);
      _categories = results[0].map(Category.fromMap).toList();
      _trending = results[1];
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
