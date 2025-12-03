import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../config.dart';

class ProfileService {
  static const String _profileIdKey = 'profile_id';

  Future<Profile> createProfile(Profile profile, {String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/profiles');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.post(url, headers: headers, body: jsonEncode(profile.toJson()));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      final created = Profile.fromJson(data as Map<String, dynamic>);
      // store id locally if present
      final prefs = await SharedPreferences.getInstance();
      if (created.id != null) {
        await prefs.setInt(_profileIdKey, created.id!);
      }
      return created;
    }
    throw Exception('Error creating profile: ${resp.statusCode}');
  }

  Future<Profile> fetchById(int id, {String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/profiles/$id');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Profile.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Error fetching profile: ${resp.statusCode}');
  }

  Future<bool> updateProfile(Profile profile, {String? token}) async {
    final url = Uri.parse('${AppConfig.apiBase}/api/v1/profiles');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.put(url, headers: headers, body: jsonEncode(profile.toJson()));
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  Future<int?> getStoredProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_profileIdKey);
  }
}
