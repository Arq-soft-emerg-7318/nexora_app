import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/community.dart';
import '../config.dart';

class CommunityService {

  Future<List<Community>> fetchAll({String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/communities/all');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }
    throw Exception('Error fetching communities: ${resp.statusCode}');
  }

  Future<Community> fetchById(int id, {String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/communities/$id');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Community.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Error fetching community: ${resp.statusCode}');
  }

  Future<List<Community>> fetchMine({String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/communities/mine');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }
    throw Exception('Error fetching my communities: ${resp.statusCode}');
  }

  Future<bool> createCommunity(String name, String? description, {String? token, int? userId}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/communities');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final body = <String, dynamic>{'name': name, 'description': description ?? ''};
    if (userId != null) body['userId'] = userId;

    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  Future<bool> joinCommunity(int communityId, {String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/communities/$communityId/join');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.post(url, headers: headers);
    // Accept 200, 201 or 204 as success depending on backend behavior
    return resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204;
  }
}
