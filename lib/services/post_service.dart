import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/post.dart';

class PostService {
  static const String _baseUrl = 'http://192.168.18.157:8080';

  Future<List<Post>> fetchPosts({String? token}) async {
    final url = Uri.parse('$_baseUrl/api/v1/posts');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } else {
      throw Exception('Error fetching posts: ${resp.statusCode}');
    }
  }

  /// Fetch posts with optional query params for title, category name, page and size.
  Future<List<Post>> fetchPostsPaged({String? title, String? category, int? categoryId, int page = 0, int size = 20, String? token}) async {
    final query = <String, String>{};
    if (title != null && title.isNotEmpty) query['title'] = title;
    if (categoryId != null) query['categoryId'] = categoryId.toString();
    else if (category != null && category.isNotEmpty && category.toLowerCase() != 'todos') query['category'] = category;
    query['page'] = page.toString();
    query['size'] = size.toString();

    final url = Uri.parse('$_baseUrl/api/v1/posts').replace(queryParameters: query);
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }
    throw Exception('Error fetching posts paged: ${resp.statusCode}');
  }

  /// Sends a like for [postId]. Returns the updated count if the server
  /// includes it in the response body, otherwise returns null.
  Future<int?> likePost({required int postId, int? userId, String? token}) async {
    final url = Uri.parse('$_baseUrl/api/v1/likes');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final body = <String, dynamic>{'postId': postId};
    if (userId != null) body['userId'] = userId;

    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    // DEBUG: log POST response for diagnostics
    try {
      // ignore: avoid_print
      print('POST ${url.toString()} -> ${resp.statusCode} ${resp.body}');
    } catch (_) {}

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // The POST typically returns the created like object (id, userId, postId)
      // which is not the authoritative like count. To avoid accidentally
      // using an id (or summing numeric fields) as the count, query the
      // authoritative count endpoint and return that value instead.
      try {
        final count = await getLikeCount(postId, token: token);
        return count;
      } catch (_) {
        // If fetching the count fails, return null so caller can decide
        // to keep the optimistic value or try a fetch later.
        return null;
      }
    }
    return null;
  }

  Future<int> getLikeCount(int postId, {String? token}) async {
    final url = Uri.parse('$_baseUrl/api/v1/likes/post/$postId/count');
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);
    // DEBUG: log GET response for diagnostics
    try {
      // ignore: avoid_print
      print('GET ${url.toString()} -> ${resp.statusCode} ${resp.body}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body);
        if (data is int) return data;
        if (data is Map) {
          // try common keys
          if (data['likes'] is int) return data['likes'] as int;
          if (data['count'] is int) return data['count'] as int;
          if (data['total'] is int) return data['total'] as int;
          // if the map contains exactly one numeric entry, return it
          if (data.length == 1) {
            final v = data.values.first;
            if (v is int) return v;
            if (v is String) return int.tryParse(v) ?? 0;
          }
          // sum numeric values as a fallback
          int sum = 0;
          for (final v in data.values) {
            if (v is int) sum += v;
            else if (v is String) sum += int.tryParse(v) ?? 0;
          }
          return sum;
        }
        // fallback try parse as int
        return int.tryParse(resp.body) ?? 0;
      } catch (_) {
        return 0;
      }
    }
    throw Exception('Error fetching like count: ${resp.statusCode}');
  }
}
