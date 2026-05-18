import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';
import 'api_service.dart';

class AlertService {
  static String get _base => '${ApiService.base}/api/alerts';

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<AlertModel>> getAlerts(String token) async {
    try {
      final res = await http.get(Uri.parse(_base), headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['alerts'] as List).map((e) => AlertModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<AlertModel?> createAlert(
      String token, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(_base),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        return AlertModel.fromJson(jsonDecode(res.body)['alert']);
      }
    } catch (_) {}
    return null;
  }

  static Future<AlertModel?> updateAlert(
      String token, String id, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/$id'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return AlertModel.fromJson(jsonDecode(res.body)['alert']);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteAlert(String token, String id) async {
    try {
      final res = await http.delete(Uri.parse('$_base/$id'), headers: _headers(token));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
