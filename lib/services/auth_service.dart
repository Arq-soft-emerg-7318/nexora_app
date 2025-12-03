import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as sp;
import '../config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<bool> signUp({required String username, required String password, List<String>? roles}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/authentication/sign-up');
    final body = jsonEncode({
      'username': username,
      'password': password,
      'roles': roles ?? ['USER'],
    });

    final resp = await http.post(url, headers: {
      'Content-Type': 'application/json',
    }, body: body);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return true;
    } else {
      String msg = 'Error en signUp: ${resp.statusCode}';
      try {
        final data = jsonDecode(resp.body);
        if (data is Map && data['message'] != null) msg = data['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<bool> signIn({required String username, required String password}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/authentication/sign-in');
    final body = jsonEncode({
      'username': username,
      'password': password,
    });

    final resp = await http.post(url, headers: {
      'Content-Type': 'application/json',
    }, body: body);

    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body);
        String? token;
        if (data is Map) {
          token = data['token'] ?? data['accessToken'] ?? data['jwt'] ?? data['data']?['token'];
        }
        if (token != null && token.isNotEmpty) {
          final prefs = await sp.SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
        }
        return true;
      } catch (e) {
        throw Exception('Error procesando respuesta: ${e.toString()}');
      }
    } else {
      String msg = 'Error en signIn: ${resp.statusCode}';
      try {
        final data = jsonDecode(resp.body);
        if (data is Map && data['message'] != null) msg = data['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> signOut() async {
    final prefs = await sp.SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await sp.SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
