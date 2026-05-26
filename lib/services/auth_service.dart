import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../core/config/app_config.dart';

const _kToken  = 'auth_token';
const _kName   = 'auth_name';
const _kEmail  = 'auth_email';
const _kAvatar = 'auth_avatar';

class AuthUser {
  final String token;
  final String name;
  final String email;
  final String? avatar;

  const AuthUser({
    required this.token,
    required this.name,
    required this.email,
    this.avatar,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final _googleSignIn = GoogleSignIn(
    // clientId: iOS only (Android reads from google-services.json automatically)
    clientId: AppConfig.isES
        ? '1081912516202-8f3nhmshf0bjqu2f307nbj2rcif5s1td.apps.googleusercontent.com'
        : '1081912516202-gmlea5u7v09vqdkjjnpnejq4mjvpoj0j.apps.googleusercontent.com',
    serverClientId: '1081912516202-i3h296sefubtsjhhhno72rrk6sdn27p3.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthUser? _user;
  bool _loading = false;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null || token.isEmpty) return;
    _user = AuthUser(
      token:  token,
      name:   prefs.getString(_kName)  ?? '',
      email:  prefs.getString(_kEmail) ?? '',
      avatar: prefs.getString(_kAvatar),
    );
    notifyListeners();
  }

  Future<void> _persist(AuthUser u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, u.token);
    await prefs.setString(_kName,  u.name);
    await prefs.setString(_kEmail, u.email);
    if (u.avatar != null) {
      await prefs.setString(_kAvatar, u.avatar!);
    } else {
      await prefs.remove(_kAvatar);
    }
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kAvatar);
  }

  // ── Google Sign-In (native) ───────────────────────────────────────────────

  Future<AuthUser?> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('Google sign-in: no idToken returned');
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiService.base}/auth/google/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode != 200) {
        debugPrint('Backend /auth/google/token error: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;

      _user = AuthUser(
        token:  data['token']  as String,
        name:   data['name']   as String? ?? '',
        email:  data['email']  as String? ?? '',
        avatar: data['avatar'] as String?,
      );
      await _persist(_user!);
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void updateName(String name) {
    if (_user == null) return;
    _user = AuthUser(
      token:  _user!.token,
      name:   name,
      email:  _user!.email,
      avatar: _user!.avatar,
    );
    _persist(_user!);
    notifyListeners();
  }

  void signOut() {
    _googleSignIn.signOut();
    _user = null;
    _clearPersisted();
    notifyListeners();
  }
}
