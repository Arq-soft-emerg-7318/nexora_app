import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/auth_notifier.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/community_service.dart';
import '../models/community.dart';
import '../models/post.dart';
import 'explore_screen.dart';
import 'create_screen.dart';
import 'trends_screen.dart';
import 'profile_screen.dart';
import 'post_detail_screen.dart';
import '../utils/text_utils.dart';

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
                  icon: Icons.group_add,
                  activeIcon: Icons.group_add,
                  label: 'Comunidades',
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
  final UserService _userService = UserService();
  Map<int, String> _userEmails = {};
  Map<int, String> _usernames = {};
  final CommunityService _communityService = CommunityService();
  List<Community> _myCommunities = [];
  Map<int, String> _communityNames = {};
  int? _selectedCommunityFilter;
  List<Post> _posts = [];
  bool _loading = true;
  final Set<int> _liking = {}; // posts being liked (loading state per post)
  final Set<int> _likedPosts = {}; // posts liked by current user in this session

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
      // Fetch users' emails and usernames so we can display author email when available
      try {
        final emails = await _userService.fetchEmails(token: token);
        if (mounted) setState(() => _userEmails = emails);
      } catch (_) {}
      try {
        final names = await _userService.fetchUsernames(token: token);
        if (mounted) setState(() => _usernames = names);
      } catch (_) {}

      // Fetch user's communities to enable filtering in the feed
      try {
        final mine = await _communityService.fetchMine(token: token);
        if (mounted) setState(() => _myCommunities = mine);
      } catch (_) {}

      // For each distinct communityId present in posts, fetch community details (id -> name)
      try {
        final ids = posts.map((p) => p.communityId).where((id) => id != null).cast<int>().toSet();
        final futures = ids.map((id) async {
          try {
            final c = await _communityService.fetchById(id, token: token);
            return MapEntry(id, c.name);
          } catch (_) {
            return MapEntry(id, 'Comunidad $id');
          }
        }).toList();
        final results = await Future.wait(futures);
        final cmap = <int, String>{};
        for (final e in results) cmap[e.key] = e.value;
        if (mounted) setState(() => _communityNames = cmap);
      } catch (_) {}

      // Fetch authoritative like counts for all posts in parallel,
      // then update the posts list so the UI shows counts from the likes API.
      final futures = posts.map((p) async {
        try {
          final count = await _postService.getLikeCount(p.id, token: token);
          return p.copyWith(reactions: count);
        } catch (_) {
          // on failure, keep original reactions value
          return p;
        }
      }).toList();

      final updated = await Future.wait(futures);
      var finalList = updated;
      if (_selectedCommunityFilter != null) {
        finalList = finalList.where((p) => p.communityId == _selectedCommunityFilter).toList();
      }
      setState(() {
        _posts = finalList;
      });
    } catch (e) {
      // ignore and show empty list / snack
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLike(Post post) async {
    final postId = post.id;
    // Prevent double-like in session
    if (_likedPosts.contains(postId)) return;
    if (_liking.contains(postId)) return;
    // optimistic update: increment locally immediately to avoid flicker
    final prev = post.reactions ?? 0;
    setState(() {
      _liking.add(postId);
      _likedPosts.add(postId);
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
        // remove liked flag on failure so user can retry
        _likedPosts.remove(postId);
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
                ],
              )

            ),

            const SizedBox(height: 24),

            // Filtro por mis comunidades (chips horizontales)
            if (_myCommunities.isNotEmpty) ...[
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1 + _myCommunities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        final active = _selectedCommunityFilter == null;
                        return ChoiceChip(
                          label: const Text('Todas'),
                          selected: active,
                          onSelected: (_) {
                            setState(() => _selectedCommunityFilter = null);
                            _loadPosts();
                          },
                          selectedColor: const Color(0xFF5B9FED),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(color: active ? Colors.white : Colors.black87),
                        );
                      }
                      final comm = _myCommunities[idx - 1];
                      final active = _selectedCommunityFilter == comm.id;
                      return ChoiceChip(
                        label: Text(comm.name),
                        selected: active,
                        onSelected: (_) {
                          setState(() => _selectedCommunityFilter = active ? null : comm.id);
                          _loadPosts();
                        },
                        selectedColor: const Color(0xFF5B9FED),
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(color: active ? Colors.white : Colors.black87),
                        avatar: CircleAvatar(
                          backgroundColor: const Color(0xFF5B9FED).withOpacity(0.2),
                          child: Text(comm.name.isNotEmpty ? comm.name[0].toUpperCase() : '?', style: TextStyle(color: const Color(0xFF5B9FED))),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Feed de posts
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: _posts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                              children: [
                                Center(
                                  child: Text(
                                    _selectedCommunityFilter != null
                                        ? 'No se encontraron posts en esa comunidad'
                                        : 'No se encontraron posts',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ),
                                const SizedBox(height: 200),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _posts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _posts.length) return const SizedBox(height: 80);
                                final post = _posts[index];
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PostDetailScreen(post: post),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: _buildPostCardFromPost(post),
                                    ),
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

  // Removed unused helper to avoid analyzer warnings. Per-post rendering
  // is implemented in `_buildPostCardFromPost` which uses cached
  // `_userEmails` and `_communityNames` maps.

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
                        sanitizeText(_usernames[post.authorId] ?? (post.authorId != null ? 'Usuario ${post.authorId}' : 'Usuario')),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.communityId != null ? (_communityNames[post.communityId] ?? 'Comunidad ${post.communityId}') : ''}',
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
            // Título (si existe) y cuerpo
            if (post.title.trim().isNotEmpty) ...[
              Text(
                sanitizeText(post.title),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              sanitizeText(post.body),
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
                  onPressed: (_liking.contains(post.id) || _likedPosts.contains(post.id)) ? null : () => _onLike(post),
                  icon: _likedPosts.contains(post.id)
                      ? const Icon(Icons.thumb_up, color: Color(0xFF5B9FED), size: 18)
                      : Icon(Icons.thumb_up_alt_outlined, color: Colors.grey[500], size: 18),
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
