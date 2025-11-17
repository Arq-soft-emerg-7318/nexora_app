import 'dart:convert';

import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _service = AuthService();
  String? _token;
  bool _loading = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;

  AuthNotifier() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _loading = true;
    notifyListeners();
    try {
      final t = await _service.getToken();
      _token = t;
    } catch (_) {
      _token = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Recarga el token desde almacenamiento (SharedPreferences).
  /// Útil si otro flujo actualizó el token y queremos refrescar el estado en memoria.
  Future<void> reloadToken() async {
    await _loadToken();
  }

  /// Devuelve true si el token actual está expirado (o no existe).
  /// `leewaySeconds` permite considerar expiración adelantada.
  bool isTokenExpired({int leewaySeconds = 0}) {
    try {
      if (_token == null || _token!.isEmpty) return true;
      final parts = _token!.split('.');
      if (parts.length < 2) return true;
      var payload = parts[1];
      // normalize base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final decoded = String.fromCharCodes(base64.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      if (map.containsKey('exp')) {
        final exp = map['exp'];
        if (exp is int) {
          final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          return (exp - leewaySeconds) <= now;
        } else if (exp is String) {
          final expInt = int.tryParse(exp) ?? 0;
          final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          return (expInt - leewaySeconds) <= now;
        }
      }
      // if no exp claim, consider it expired to be safe
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> signIn({required String username, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final ok = await _service.signIn(username: username, password: password);
      if (ok) {
        _token = await _service.getToken();
        notifyListeners();
      }
      return ok;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({required String username, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final ok = await _service.signUp(username: username, password: password);
      if (ok) {
        // attempt sign in to obtain token
        final signinOk = await _service.signIn(username: username, password: password);
        if (signinOk) _token = await _service.getToken();
        notifyListeners();
        return signinOk;
      }
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.signOut();
      _token = null;
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
