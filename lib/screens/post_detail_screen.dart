import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_notifier.dart';
import '../utils/text_utils.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  late Post _post;
  bool _liking = false;
  bool _liked = false;
  String? _authorName;

  // local category map (can be replaced by API/service if available)
  final Map<int, String> _categoryById = {
    1: 'Industrial',
    2: 'Innovación',
    3: 'Seguridad',
    4: 'Geología',
    5: 'Sostenibilidad',
  };

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    // Load author username if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAuthorName();
    });
  }

  Future<void> _loadAuthorName() async {
    try {
      if (_post.authorId == null) return;
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final map = await UserService().fetchUsernames(token: token);
      if (mounted) setState(() => _authorName = map[_post.authorId!]);
    } catch (_) {}
  }

  Future<void> _onLike() async {
    if (_liking || _liked) return;
    final postId = _post.id;
    final prev = _post.reactions ?? 0;
    setState(() {
      _liking = true;
      _post = _post.copyWith(reactions: prev + 1);
      _liked = true;
    });

    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final updated = await _postService.likePost(postId: postId, token: token);
      if (updated != null) {
        final safe = updated < (prev + 1) ? (prev + 1) : updated;
        if (mounted) setState(() => _post = _post.copyWith(reactions: safe));
      } else {
        // try fetch authoritative count
        try {
          final count = await _postService.getLikeCount(postId, token: token);
          final safe = count < (prev + 1) ? (prev + 1) : count;
          if (mounted) setState(() => _post = _post.copyWith(reactions: safe));
        } catch (_) {
          // keep optimistic
        }
      }
    } catch (_) {
      // revert
      if (mounted) setState(() {
        _post = _post.copyWith(reactions: prev);
        _liked = false;
      });
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _post.categoryId != null ? (_categoryById[_post.categoryId!] ?? 'General') : 'General';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title should appear above the image
            Text(
              sanitizeText(_post.title),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            if (_post.fileUrl != null && _post.fileUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_post.fileUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(
              sanitizeText(_post.body),
              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(categoryName)),
                const SizedBox(width: 8),
                if (_post.authorId != null) Text(_authorName != null ? 'Autor $_authorName' : 'Autor ${_post.authorId}'),
                const Spacer(),
                TextButton.icon(
                  onPressed: (_liking || _liked) ? null : _onLike,
                  icon: _liking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : (_liked ? const Icon(Icons.thumb_up, color: Color(0xFF5B9FED)) : const Icon(Icons.thumb_up_alt_outlined)),
                  label: Text('${_post.reactions ?? 0}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
