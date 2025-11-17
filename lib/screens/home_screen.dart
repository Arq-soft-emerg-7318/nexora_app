import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/auth_notifier.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import 'explore_screen.dart';
import 'create_screen.dart';
import 'trends_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeContentScreen(),
    ExploreScreen(),
    CreateScreen(),
    TrendsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: 'Explorar',
                  index: 1,
                ),
                _buildCreateButton(),
                _buildNavItem(
                  icon: Icons.trending_up,
                  activeIcon: Icons.trending_up,
                  label: 'Tendencias',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Perfil',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF5B9FED) : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF5B9FED) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5B9FED),
                  Color(0xFF7BB8F5),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B9FED).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crear',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF5B9FED) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({Key? key}) : super(key: key);

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _loading = true;
  final Set<int> _liking = {}; // posts being liked (loading state per post)

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final posts = await _postService.fetchPosts(token: token);
      // Fetch authoritative like counts for all posts in parallel,
      // then update the posts list so the UI shows counts from the likes API.
      final futures = posts.map((p) async {
        if (p.id == null) return p;
        try {
          final count = await _postService.getLikeCount(p.id!, token: token);
          return p.copyWith(reactions: count);
        } catch (_) {
          // on failure, keep original reactions value
          return p;
        }
      }).toList();

      final updated = await Future.wait(futures);
      setState(() {
        _posts = updated;
      });
    } catch (e) {
      // ignore and show empty list / snack
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLike(Post post) async {
    if (post.id == null) return;
    final postId = post.id!;
    if (_liking.contains(postId)) return;
    // optimistic update: increment locally immediately to avoid flicker
    final prev = post.reactions ?? 0;
    setState(() {
      _liking.add(postId);
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) _posts[idx] = _posts[idx].copyWith(reactions: prev + 1);
    });
    // DEBUG: log optimistic update
    try {
      // ignore: avoid_print
      print('LIKE_OPTIMISTIC post:$postId prev:$prev optimistic:${prev + 1}');
    } catch (_) {}

    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final updated = await _postService.likePost(postId: postId, token: token);
      if (updated != null) {
        // server returned authoritative count — avoid unrealistic drops/jumps:
        final safe = updated < (prev + 1) ? (prev + 1) : updated;
        try {
          // ignore: avoid_print
          print('LIKE_SERVER post:$postId returned:$updated safe:$safe');
        } catch (_) {}
        if (mounted) setState(() {
          final idx = _posts.indexWhere((p) => p.id == postId);
          if (idx != -1) _posts[idx] = _posts[idx].copyWith(reactions: safe);
        });
      } else {
        // server didn't return count: try to fetch authoritative count now
        try {
          final count = await _postService.getLikeCount(postId, token: token);
          final safe = count < (prev + 1) ? (prev + 1) : count;
          try {
            // ignore: avoid_print
            print('LIKE_FETCH post:$postId fetched:$count safe:$safe');
          } catch (_) {}
          if (mounted) setState(() {
            final idx = _posts.indexWhere((p) => p.id == postId);
            if (idx != -1) _posts[idx] = _posts[idx].copyWith(reactions: safe);
          });
        } catch (_) {
          // couldn't fetch fresh count, keep optimistic value
        }
      }
    } catch (e) {
      // network error -> revert optimistic
      if (mounted) setState(() {
        final idx = _posts.indexWhere((p) => p.id == postId);
        if (idx != -1) _posts[idx] = _posts[idx].copyWith(reactions: prev);
      });
    } finally {
      if (mounted) setState(() => _liking.remove(postId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F4FD),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/LOGO-NX.png',
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nexora',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: Colors.grey,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.grey,
                  ),
                ],
              )

            ),

            // Resumen del día
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B9FED), Color(0xFF7BB8F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B9FED).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '5 nuevos artículos sobre sostenibilidad, 3 actualizaciones de seguridad y 12 discusiones activas en tus comunidades.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feed de posts
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _posts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _posts.length) return const SizedBox(height: 80);
                          final post = _posts[index];
                          return Column(
                            children: [
                              _buildPostCardFromPost(post),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPostCard({
    required String name,
    required String role,
    required String time,
    required String category,
    required Color categoryColor,
    required String title,
    required String content,
    required int likes,
    required int comments,
    required Color avatarColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del post
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: avatarColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Título
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Contenido
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Ver más
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver más',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5B9FED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Acciones
            Row(
              children: [
                Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  likes.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 24),
                Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  comments.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCardFromPost(Post post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del post
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.black54, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Autor: ${post.authorId ?? '-'} • ${post.communityId != null ? 'Comunidad ${post.communityId}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  post.reactions != null ? '${post.reactions} ❤' : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Body
            Text(
              post.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            if (post.fileUrl != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<Uint8List?>(
                future: _fetchFileBytes(post.fileUrl!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final bytes = snapshot.data;
                  if (bytes != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        bytes,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  // Fallback to network image without auth header
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.fileUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: Center(
                          child: Text(
                            'No se pudo cargar el archivo',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _liking.contains(post.id) ? null : () => _onLike(post),
                  icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.grey[500], size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                if (_liking.contains(post.id))
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.grey[600])),
                  ),
                const SizedBox(width: 6),
                Text('${post.reactions ?? 0}'),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                const Text('Comentar'),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _fetchFileBytes(String url) async {
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      if (token != null && token.isNotEmpty) {
        final resp = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
        if (resp.statusCode == 200) return resp.bodyBytes;
        return null;
      } else {
        // No token: let Image.network handle it (return null to indicate fallback)
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
