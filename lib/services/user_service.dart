import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class UserService {
  final String? baseUrl;

  UserService({this.baseUrl});

  /// Fetch all users and return a map userId -> username
  Future<Map<int, String>> fetchUsernames({String? token}) async {
    final uri = Uri.parse('${baseUrl ?? AppConfig.apiBase}/api/v1/users');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) return {};
    try {
      final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
      final Map<int, String> map = {};
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final id = (item['id'] is int) ? item['id'] as int : int.tryParse(item['id']?.toString() ?? '');
          final username = item['username']?.toString() ?? '';
          if (id != null) map[id] = username;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
