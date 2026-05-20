import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../core/config/app_config.dart';

class DealsResponse {
  final List<Product> products;
  final int total;
  final int productCount;
  final int page;
  final List<String> categories;
  final List<int> discounts;

  const DealsResponse({
    required this.products,
    required this.total,
    required this.productCount,
    required this.page,
    this.categories = const [],
    this.discounts = const [],
  });
}

class ApiService {
  static String get base => AppConfig.apiBase;
  static String get _base => AppConfig.apiBase;

  static Future<DealsResponse> getDeals({
    int page = 1,
    int limit = 48,
    String? category,
    List<String>? categoryIds,
    int? discount,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      'source': 'apk',
      if (category != null && category.isNotEmpty) 'category': category,
      if (categoryIds != null && categoryIds.isNotEmpty) 'categoryIds': categoryIds.join(','),
      if (discount != null) 'discount': discount.toString(),
    };
    final uri = Uri.parse('$_base/api/promos/deals').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load deals: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (body['products'] as List? ?? []).map((e) => Product.fromJson(e)).toList();
    return DealsResponse(
      products: products,
      total: body['total'] ?? 0,
      productCount: body['productCount'] ?? body['total'] ?? 0,
      page: body['page'] ?? 1,
    );
  }

  static Future<DealsResponse> getUpcoming({
    int page = 1,
    int limit = 48,
    String? category,
    List<String>? categoryIds,
    int? discount,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      'source': 'apk',
      if (category != null && category.isNotEmpty) 'category': category,
      if (categoryIds != null && categoryIds.isNotEmpty) 'categoryIds': categoryIds.join(','),
      if (discount != null) 'discount': discount.toString(),
    };
    final uri = Uri.parse('$_base/api/promos/upcoming').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load upcoming: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (body['products'] as List? ?? []).map((e) => Product.fromJson(e)).toList();
    final filters = body['filters'] as Map<String, dynamic>? ?? {};
    return DealsResponse(
      products: products,
      total: body['total'] ?? 0,
      productCount: body['productCount'] ?? body['total'] ?? 0,
      page: body['page'] ?? 1,
      categories: List<String>.from(filters['categories'] ?? []),
      discounts: List<int>.from((filters['discounts'] ?? []).map((d) => (d as num).toInt())),
    );
  }

  static Future<DealsResponse> getEndingSoon({
    int page = 1,
    int limit = 48,
    String? category,
    List<String>? categoryIds,
    int? discount,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      'source': 'apk',
      if (category != null && category.isNotEmpty) 'category': category,
      if (categoryIds != null && categoryIds.isNotEmpty) 'categoryIds': categoryIds.join(','),
      if (discount != null) 'discount': discount.toString(),
    };
    final uri = Uri.parse('$_base/api/promos/ending-soon').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load ending soon: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (body['products'] as List? ?? []).map((e) => Product.fromJson(e)).toList();
    return DealsResponse(
      products: products,
      total: body['total'] ?? 0,
      productCount: body['productCount'] ?? body['total'] ?? 0,
      page: body['page'] ?? 1,
    );
  }

  static Future<Map<String, dynamic>> getFilters() async {
    final uri = Uri.parse('$_base/api/promos/filters');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to load filters: ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$_base/api/products/categories');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to load categories: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['categories'] as List? ?? [];
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Product>> getProductsByCode(String code) async {
    final uri = Uri.parse('$_base/api/promos/by-code/${Uri.encodeComponent(code)}')
        .replace(queryParameters: {'source': 'apk'});
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load group: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['products'] as List? ?? [];
    return list.map((e) => Product.fromJson(e)).toList();
  }

  static Future<void> addFavorite(String token, String productId) async {
    final uri = Uri.parse('$_base/api/favorites/$productId');
    final res = await http.post(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    if (res.statusCode != 201 && res.statusCode != 400) throw Exception('Add favorite failed: ${res.statusCode}');
  }

  static Future<void> removeFavorite(String token, String productId) async {
    final uri = Uri.parse('$_base/api/favorites/$productId');
    final res = await http.delete(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 && res.statusCode != 404) throw Exception('Remove favorite failed: ${res.statusCode}');
  }

  static Future<List<Product>> getFavorites(String token) async {
    final uri = Uri.parse('$_base/api/favorites').replace(queryParameters: {'source': 'apk'});
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load favorites: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['products'] as List? ?? [];
    return list.map((e) => Product.fromJson(e)).toList();
  }

  static Future<DealsResponse> getBestSellers({
    String? category,
    int minDiscount = 25,
    int limit = 20,
  }) async {
    final params = {
      'limit': limit.toString(),
      'minDiscount': minDiscount.toString(),
      'source': 'apk',
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final uri = Uri.parse('$_base/api/promos/best-sellers').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to load best sellers: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (body['products'] as List? ?? []).map((e) => Product.fromJson(e)).toList();
    return DealsResponse(
      products: products,
      total: body['total'] ?? 0,
      productCount: body['total'] ?? 0,
      page: 1,
    );
  }

  static Future<List<String>> getCategoryPreferences(String token) async {
    final uri = Uri.parse('$_base/api/users/category-preferences');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<String>.from(body['categoryIds'] ?? []);
  }

  static Future<bool> saveCategoryPreferences(String token, List<String> categoryIds) async {
    final uri = Uri.parse('$_base/api/users/category-preferences');
    final res = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'categoryIds': categoryIds}),
    ).timeout(const Duration(seconds: 10));
    return res.statusCode == 200;
  }

  static Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$_base/api/products/search').replace(
      queryParameters: {'q': query.trim(), 'limit': '48'},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Search failed: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['products'] as List? ?? body['data'] as List? ?? [];
    return list.map((e) => Product.fromJson(e)).toList();
  }
}
