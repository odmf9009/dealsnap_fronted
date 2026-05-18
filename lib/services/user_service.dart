import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UserProfile {
  final String id;
  final String name;
  final String? lastName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? birthday;
  final String gender;
  final ShippingAddress address;
  final UserPreferences preferences;
  final String authProvider;

  const UserProfile({
    required this.id,
    required this.name,
    this.lastName,
    required this.email,
    this.phone,
    this.avatar,
    this.birthday,
    this.gender = 'secret',
    required this.address,
    required this.preferences,
    this.authProvider = 'google',
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id:           j['_id'] ?? j['id'] ?? '',
        name:         j['name'] ?? '',
        lastName:     j['lastName'],
        email:        j['email'] ?? '',
        phone:        j['phone'],
        avatar:       j['avatar'],
        birthday:     j['birthday'],
        gender:       j['gender'] ?? 'secret',
        address:      ShippingAddress.fromJson(j['shippingAddress'] ?? {}),
        preferences:  UserPreferences.fromJson(j['preferences'] ?? {}),
        authProvider: j['authProvider'] ?? 'google',
      );
}

class ShippingAddress {
  final String fullName;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zipCode;

  const ShippingAddress({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
  });

  bool get isEmpty =>
      fullName.isEmpty && address1.isEmpty && city.isEmpty;

  factory ShippingAddress.fromJson(Map<String, dynamic> j) => ShippingAddress(
        fullName: j['fullName'] ?? '',
        email:    j['email']    ?? '',
        phone:    j['phone']    ?? '',
        address1: j['address1'] ?? '',
        address2: j['address2'] ?? '',
        city:     j['city']     ?? '',
        state:    j['state']    ?? '',
        zipCode:  j['zipCode']  ?? '',
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email':    email,
        'phone':    phone,
        'address1': address1,
        'address2': address2,
        'city':     city,
        'state':    state,
        'zipCode':  zipCode,
      };
}

class UserPreferences {
  final bool emailNotifications;
  final List<String> categories;
  final List<String> stores;
  final List<String> dealPriorities;

  const UserPreferences({
    this.emailNotifications = true,
    this.categories = const [],
    this.stores = const [],
    this.dealPriorities = const [],
  });

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
        emailNotifications: j['emailNotifications'] ?? true,
        categories:    List<String>.from(j['categories']    ?? []),
        stores:        List<String>.from(j['stores']        ?? []),
        dealPriorities: List<String>.from(j['dealPriorities'] ?? []),
      );
}

class UserService {
  static String get _base => '${ApiService.base}/api/users';

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // GET /api/users/me
  static Future<UserProfile?> getProfile(String token) async {
    try {
      final res = await http.get(Uri.parse('$_base/me'), headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return UserProfile.fromJson(data['user']);
      }
    } catch (_) {}
    return null;
  }

  // PATCH /api/users/me
  static Future<UserProfile?> updateProfile(String token, Map<String, dynamic> fields) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/me'),
        headers: _headers(token),
        body: jsonEncode(fields),
      );
      if (res.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(res.body)['user']);
      }
    } catch (_) {}
    return null;
  }

  // PUT /api/users/me/password
  static Future<String?> changePassword(
      String token, String? currentPassword, String newPassword) async {
    try {
      final body = <String, String>{'newPassword': newPassword};
      if (currentPassword != null) body['currentPassword'] = currentPassword;
      final res = await http.put(
        Uri.parse('$_base/me/password'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return null; // success
      return data['message'] ?? 'Error';
    } catch (_) {
      return 'Connection error';
    }
  }

  // PUT /api/users/me/address
  static Future<ShippingAddress?> updateAddress(
      String token, ShippingAddress address) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/me/address'),
        headers: _headers(token),
        body: jsonEncode(address.toJson()),
      );
      if (res.statusCode == 200) {
        return ShippingAddress.fromJson(jsonDecode(res.body)['shippingAddress']);
      }
    } catch (_) {}
    return null;
  }

  // PUT /api/users/me/preferences
  static Future<bool> updatePreferences(
      String token, Map<String, dynamic> prefs) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/me/preferences'),
        headers: _headers(token),
        body: jsonEncode(prefs),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // DELETE /api/users/me
  static Future<bool> deleteAccount(String token) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base/me'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
