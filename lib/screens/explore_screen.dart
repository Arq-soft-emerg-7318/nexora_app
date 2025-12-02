import 'dart:async';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import 'post_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';

  final List<String> _filters = [
    'Todos',
    'Industrial',
    'Innovación',
    'Seguridad',
    'Geología',
    'Sostenibilidad'
  ];

  // Pagination / posts state
  final PostService _postService = PostService();
  final List<Post> _posts = [];
  int _page = 0;
  final int _size = 10;
  bool _loading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // category id -> name map (if API returns ids)
  final Map<int, String> _categoryById = {
    1: 'Industrial',
    2: 'Innovación',
    3: 'Seguridad',
    4: 'Geología',
    5: 'Sostenibilidad',
  };

  // name -> id map to send categoryId to backend when possible
  final Map<String, int> _categoryNameToId = {
    'Industrial': 1,
    'Innovación': 2,
    'Seguridad': 3,
    'Geología': 4,
    'Sostenibilidad': 5,
  };

  Timer? _searchDebounce;

  // removed recent search samples and popular topics — posts come from backend

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Debounce user typing to avoid many requests
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        _page = 0;
        _hasMore = true;
        _posts.clear();
        _loadPosts();
      });
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_loading && _hasMore) _loadPosts();
      }
    });
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!_hasMore) return;
    setState(() => _loading = true);
    try {
      final title = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
      final category = _selectedFilter == 'Todos' ? null : _selectedFilter;
      final int? categoryId = _categoryNameToId[_selectedFilter];
      final fetched = await _postService.fetchPostsPaged(title: title, category: category, categoryId: categoryId, page: _page, size: _size);
      // If backend does not filter by category name, apply client-side filter by category
      List<Post> filteredFetched = fetched;
      if (category != null && category.isNotEmpty) {
        filteredFetched = fetched.where((p) {
          final name = p.categoryId != null ? (_categoryById[p.categoryId!] ?? '') : '';
          return name.toLowerCase() == category.toLowerCase();
        }).toList();
      }
      setState(() {
        if (_page == 0) _posts.clear();
        _posts.addAll(filteredFetched);
        _hasMore = fetched.length == _size; // still decide hasMore based on raw fetched size
        if (_hasMore) _page += 1;
      });
    } catch (e) {
      // ignore fetch errors for now
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: const Text(
                'Explorar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B9FED),
                ),
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar artículos, noticias, documentos...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: const Color(0xFF5B9FED),
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filtros
            SizedBox(
              height: 45,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _page = 0;
                          _hasMore = true;
                          _posts.clear();
                        });
                        _loadPosts();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF5B9FED),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF5B9FED)
                            : Colors.grey[300]!,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Contenido scrollable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Publicaciones recientes (desde backend)
                  const Text(
                    'Publicaciones recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),
                  // Posts from backend
                  RefreshIndicator(
                    onRefresh: () async {
                      _page = 0;
                      _hasMore = true;
                      _posts.clear();
                      await _loadPosts();
                    },
                    child: Column(
                      children: [
                        if (_posts.isEmpty && _loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          )
                        else if (_posts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Center(
                              child: Text('No se encontraron resultados', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else ..._posts.map((post) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
                            },
                            child: _buildDocumentCard(
                              title: post.title,
                              category: post.categoryId != null ? (_categoryById[post.categoryId!] ?? 'General') : 'General',
                              date: 'Reciente',
                            ),
                          ),
                        )),
                        const SizedBox(height: 8),
                        if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()),
                        if (!_loading && _hasMore)
                          TextButton(onPressed: _loadPosts, child: const Text('Cargar más')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // popular topics removed

  Widget _buildDocumentCard({
    required String title,
    required String category,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B9FED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B9FED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
}