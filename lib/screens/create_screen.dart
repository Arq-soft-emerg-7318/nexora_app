import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import 'ai_preview_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../services/auth_notifier.dart';
import '../services/community_service.dart';
import '../models/community.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../config.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();

  final CommunityService _communityService = CommunityService();
  List<Community> _myCommunities = [];
  int? _selectedCommunityId;

  // category name -> id mapping (sample ids). Ajusta más tarde con endpoint real.
  final Map<String, int> _categoryMap = {
    'Industrial': 1,
    'Innovación': 2,
    'Seguridad': 3,
    'Geología': 4,
    'Sostenibilidad': 5,
  };

  String _selectedCategory = 'Industrial';
  File? _selectedFile;
  bool _posting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadMyCommunities();
  }

  Future<void> _loadMyCommunities() async {
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final list = await _communityService.fetchMine(token: token);
      if (mounted) setState(() => _myCommunities = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // If this screen was pushed on the navigator stack, pop it.
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            // Otherwise (likely shown as a bottom-tab view), navigate to HomeScreen.
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Nueva publicación',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),

          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asistente IA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5B9FED).withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B9FED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF5B9FED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente IA de Nexora',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Deja que la inteligencia artificial te ayude a crear contenido profesional y relevante',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAIAssistantDialog();
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Ver cómo puede ayudarte la IA'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B9FED),
                        side: const BorderSide(color: Color(0xFF5B9FED)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Categoría (single select)
            const Text(
              'Categoría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categoryMap.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            const Text(
              'Título',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Escribe un título',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Comunidad (selector basado en tus comunidades)
            const Text(
              'Comunidad (opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedCommunityId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Ninguna')),
                ..._myCommunities.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))
              ],
              onChanged: (v) => setState(() => _selectedCommunityId = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 28),

            // Contenido
            const Text(
              'Contenido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: '¿Qué quieres compartir con la comunidad minera?',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(fontSize: 12),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Adjuntar
            const Text(
              'Adjuntar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.attach_file_outlined,
                    label: _selectedFile != null ? 'Archivo seleccionado' : 'Adjuntar archivo',
                    onTap: _pickFile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.link,
                    label: 'Enlace',
                    onTap: () {
                      _showLinkDialog();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_selectedFile != null) ...[
              _isImageFile(_selectedFile!)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: InteractiveViewer(child: Image.file(_selectedFile!)),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_full, size: 18),
                              label: const Text('Ver'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedFile = null);
                              },
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              label: const Text('Quitar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Text('Archivo: ${_selectedFile!.path.split('/').last}', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _posting ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B9FED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _posting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Publicar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedFile = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error seleccionando imagen: $e')));
    }
  }

  // helper removed; uploadService will detect mime type.

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Título y contenido son obligatorios')));
      return;
    }

    setState(() => _posting = true);
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token no disponible')));
        setState(() => _posting = false);
        return;
      }
      final categoryId = _categoryMap[_selectedCategory];
      int? communityId = _selectedCommunityId;

      // sanitize body: remove markdown emphasis, base64/image blobs and any http(s) urls
      final sanitizedBody = _removeUrls(_sanitizeText(body));

      final Map<String, dynamic> postObj = {
        'title': title,
        'authorId': null,
        'body': sanitizedBody,
        'categoryId': categoryId,
        // 'reactions' omitted intentionally
        'fileId': 0,
        'communityId': communityId,
      };

      // Prepare upload file (compress if possible) and call UploadService
      File? uploadFile;
      if (_selectedFile != null && await _selectedFile!.exists()) {
        try {
          final compressed = await FlutterImageCompress.compressWithFile(
            _selectedFile!.path,
            quality: 70,
          );
          if (compressed != null && compressed.isNotEmpty) {
            // write compressed bytes to temp file
            final tmp = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}');
            await tmp.writeAsBytes(compressed);
            uploadFile = tmp;
          } else {
            uploadFile = _selectedFile;
          }
        } catch (_) {
          uploadFile = _selectedFile;
        }
      }

      try {
        // Antes de intentar subir, validar expiración local del token
        // `auth` ya fue obtenido arriba en el método (_publish)
        if (auth.isTokenExpired(leewaySeconds: 5)) {
          final goLogin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sesión inválida'),
              content: const Text('Tu sesión ha expirado o es inválida. ¿Deseas iniciar sesión ahora?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Iniciar sesión')),
              ],
            ),
          );
          if (goLogin == true) {
            try {
              await auth.signOut();
            } catch (_) {}
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            return;
          }
        }

        final tokenToUse = auth.token ?? token;

        final resp = await UploadService.uploadPost(tokenToUse, postObj, uploadFile);
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación creada'), backgroundColor: Color(0xFF5B9FED)));
          _titleController.clear();
          _contentController.clear();
          _communityController.clear();
          setState(() => _selectedFile = null);
          if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        } else if (resp.statusCode == 401) {
          // Intentar recargar token desde almacenamiento y reintentar una vez
          await auth.reloadToken();
          final newToken = auth.token;
          if (newToken != null && newToken.isNotEmpty && newToken != token) {
            // reintentar con token recargado
            try {
              final retryResp = await UploadService.uploadPost(newToken, postObj, uploadFile);
                if (retryResp.statusCode == 200 || retryResp.statusCode == 201) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación creada'), backgroundColor: Color(0xFF5B9FED)));
                _titleController.clear();
                _contentController.clear();
                _communityController.clear();
                setState(() => _selectedFile = null);
                if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                return;
              }
            } catch (_) {}
          }

          // Si llegamos aquí, seguir con flujo de re-login
          final goLogin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sesión expirada'),
              content: const Text('Tu sesión ha expirado. ¿Quieres iniciar sesión de nuevo?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Iniciar sesión')),
              ],
            ),
          );

          if (goLogin == true) {
            try {
              await auth.signOut();
            } catch (_) {}
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }
        } else {
          String msg = 'Error creando publicación: ${resp.statusCode}';
          try {
            final data = resp.data;
            if (data is Map && data['message'] != null) msg = data['message'];
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF5B9FED),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIAssistantDialog() {
    final promptController = TextEditingController();
    bool isGenerating = false;
    String? genTitle;
    String? genBody;
    String? genCategory;
    int? genCommunityId;
    String? genImageBase64;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDlgState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(Icons.auto_awesome, color: const Color(0xFF5B9FED), size: 26),
            const SizedBox(width: 10),
            const Text('Generador IA'),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: promptController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Describe lo que quieres que genere...'),
              ),
              const SizedBox(height: 12),
              if (isGenerating) const CircularProgressIndicator(),
              if (genTitle != null) ...[
                Align(alignment: Alignment.centerLeft, child: const Text('Título sugerido', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(_truncateWords(genTitle!, 5), style: const TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(
                    onPressed: () async {
                      final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AiPreviewScreen(
                        title: genTitle != null ? _sanitizeText(genTitle!) : null,
                        body: genBody != null ? _sanitizeText(genBody!) : null,
                        imageBase64: genImageBase64,
                      )));
                        if (res is Map) {
                        // apply returned values
                        setState(() {
                          if (res['title'] != null) _titleController.text = _sanitizeAndTruncateTitle((res['title'] as String), 5);
                          if (res['body'] != null) _contentController.text = _sanitizeText((res['body'] as String));
                          if (res['image'] != null) {
                            try {
                              final bytes = base64Decode(res['image'] as String);
                              final tmpDir = Directory.systemTemp.createTempSync('nexora_ai_');
                              final f = File('${tmpDir.path}/ai_generated_${DateTime.now().millisecondsSinceEpoch}.png');
                              f.writeAsBytesSync(bytes);
                              _selectedFile = f;
                            } catch (_) {}
                          }
                        });
                      }
                    },
                    child: const Text('Ver más'),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
              if (genBody != null) ...[
                Align(alignment: Alignment.centerLeft, child: const Text('Texto generado', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Text(_shortenText(_sanitizeText(genBody!), 60)),
                const SizedBox(height: 8),
              ],
              if (genImageBase64 != null) ...[
                Align(alignment: Alignment.centerLeft, child: const Text('Imagen generada', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Image.memory(base64Decode(genImageBase64!), height: 160, fit: BoxFit.cover),
                const SizedBox(height: 8),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            TextButton(
              onPressed: isGenerating
                  ? null
                  : () async {
                      final prompt = promptController.text.trim();
                      if (prompt.isEmpty) return;
                      setDlgState(() => isGenerating = true);
                      try {
                        final data = await _generateFromEndpoint(prompt);
                        // Expect fields: title, category, communityId (or community), text/body, image (base64)
                        genTitle = data['title'] as String? ?? data['text'] as String?;
                        genBody = (data['body'] as String?) ?? (data['text'] as String?) ?? data['message'] as String?;
                        // category may be name or id
                        final cat = data['category'];
                        if (cat != null) genCategory = cat is String ? cat : cat.toString();
                        final community = data['communityId'] ?? data['community'] ?? data['community_id'];
                        if (community != null) genCommunityId = (community is int) ? community : int.tryParse(community.toString());
                        genImageBase64 = data['image'] as String?;

                        setDlgState(() => isGenerating = false);
                        setState(() {
                          if (genTitle != null) _titleController.text = _sanitizeAndTruncateTitle(genTitle!, 5);
                          if (genBody != null) _contentController.text = _sanitizeText(genBody!);
                          if (genCategory != null) {
                            // try match by name, otherwise if numeric try map by id
                            if (_categoryMap.containsKey(genCategory)) {
                              _selectedCategory = genCategory!;
                            } else {
                              final maybeId = int.tryParse(genCategory!);
                              if (maybeId != null) {
                                final entry = _categoryMap.entries.firstWhere((e) => e.value == maybeId, orElse: () => MapEntry(_selectedCategory, _categoryMap[_selectedCategory]!));
                                _selectedCategory = entry.key;
                              }
                            }
                          }
                          if (genCommunityId != null) _communityController.text = genCommunityId.toString();
                        });

                        // if image present, write temp file and set _selectedFile so it is uploaded
                        if (genImageBase64 != null) {
                          try {
                            final bytes = base64Decode(genImageBase64!);
                            final tmpDir = await Directory.systemTemp.createTemp('nexora_ai_');
                            final f = File('${tmpDir.path}/ai_generated_${DateTime.now().millisecondsSinceEpoch}.png');
                            await f.writeAsBytes(bytes);
                            setState(() => _selectedFile = f);
                          } catch (e) {
                            // ignore file write errors but inform
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen generada, pero no se pudo guardar: $e')));
                          }
                        }
                      } catch (e) {
                        setDlgState(() => isGenerating = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generando: $e')));
                      }
                    },
              child: const Text('Generar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // If nothing generated yet, generate first
                if (!isGenerating && genTitle == null && genBody == null && genImageBase64 == null) {
                  final prompt = promptController.text.trim();
                  if (prompt.isEmpty) return;
                  setDlgState(() => isGenerating = true);
                  try {
                    final data = await _generateFromEndpoint(prompt);
                    genTitle = data['title'] as String? ?? data['text'] as String?;
                    genBody = (data['body'] as String?) ?? (data['text'] as String?) ?? data['message'] as String?;
                    final cat = data['category'];
                    if (cat != null) genCategory = cat is String ? cat : cat.toString();
                    final community = data['communityId'] ?? data['community'] ?? data['community_id'];
                    if (community != null) genCommunityId = (community is int) ? community : int.tryParse(community.toString());
                    genImageBase64 = data['image'] as String?;

                    setDlgState(() => isGenerating = false);
                      setState(() {
                        if (genTitle != null) _titleController.text = _truncateWords(genTitle!, 5);
                        if (genBody != null) _contentController.text = _sanitizeText(genBody!);
                        if (genCategory != null) {
                        if (_categoryMap.containsKey(genCategory)) {
                          _selectedCategory = genCategory!;
                        } else {
                          final maybeId = int.tryParse(genCategory!);
                          if (maybeId != null) {
                            final entry = _categoryMap.entries.firstWhere((e) => e.value == maybeId, orElse: () => MapEntry(_selectedCategory, _categoryMap[_selectedCategory]!));
                            _selectedCategory = entry.key;
                          }
                        }
                      }
                      if (genCommunityId != null) _communityController.text = genCommunityId.toString();
                    });

                    if (genImageBase64 != null) {
                      try {
                        final bytes = base64Decode(genImageBase64!);
                        final tmpDir = await Directory.systemTemp.createTemp('nexora_ai_');
                        final f = File('${tmpDir.path}/ai_generated_${DateTime.now().millisecondsSinceEpoch}.png');
                        await f.writeAsBytes(bytes);
                        setState(() => _selectedFile = f);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen generada, pero no se pudo guardar: $e')));
                      }
                    }
                  } catch (e) {
                    setDlgState(() => isGenerating = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generando: $e')));
                    return;
                  }
                }

                // Close after applying
                Navigator.pop(context);
              },
              child: const Text('Aplicar en formulario'),
            ),
          ],
        );
      }),
    );
  }

  Future<Map<String, dynamic>> _generateFromEndpoint(String prompt) async {
    final url = Uri.parse('${AppConfig.aiBase}/generate');
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'prompt': _shortenPrompt(prompt)}));
    if (resp.statusCode != 200) throw Exception('IA endpoint error ${resp.statusCode}: ${resp.body}');
    final data = jsonDecode(resp.body);
    if (data is Map<String, dynamic>) return data;
    return {'text': data.toString()};
  }

  String _truncateWords(String s, int maxWords) {
    // Cortar el título en la primera nueva línea y limitar por número de palabras
    final firstLine = s.split('\n').first.trim();
    final parts = firstLine.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length <= maxWords) return parts.join(' ');
    return parts.sublist(0, maxWords).join(' ');
  }

  String _shortenText(String s, int maxWords) {
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length <= maxWords) return s;
    return parts.sublist(0, maxWords).join(' ') + '...';
  }

  String _shortenPrompt(String prompt) {
    // Append guidance so the IA returns concise content suitable for preview and short posts
    return prompt + '\n\nPor favor responde con un título (máx 5 palabras) y un texto breve (máx 60 palabras). Incluye una imagen en base64 en la clave "image" cuando corresponda.';
  }

  String _sanitizeText(String s) {
    // Remove markdown emphasis characters and any inline/base64 image data
    String clean = s.replaceAll('**', '').replaceAll('*', '').replaceAll('`', '').trim();
    // Remove lines that look like image: <base64...> or data:image/... blobs
    clean = _removeImageData(clean);
    return clean;
  }

  String _removeImageData(String s) {
    // Remove any lines that start with 'image:' or 'imagen:' (case-insensitive),
    // or lines that contain 'data:image' or long base64 fragments.
    final lines = s.split(RegExp(r'\r?\n'));
    final filtered = <String>[];
    final base64Long = RegExp(r'^[A-Za-z0-9+/=\\s]{100,}\$');
    for (var line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final low = t.toLowerCase();
      if (low.startsWith('image:') || low.startsWith('imagen:')) continue;
      if (low.contains('data:image')) continue;
      if (base64Long.hasMatch(t)) continue;
      filtered.add(t);
    }
    return filtered.join('\n').trim();
  }

  String _removeUrls(String s) {
    // Remove http(s) and www links from the text to avoid embedding image URLs inside the body
    final urlRegex = RegExp(r'https?:\/\/\S+|www\.\S+', caseSensitive: false);
    final lines = s.split(RegExp(r'\r?\n'));
    final cleaned = <String>[];
    for (var line in lines) {
      var t = line.replaceAll(urlRegex, '').trim();
      if (t.isEmpty) continue;
      cleaned.add(t);
    }
    return cleaned.join('\n');
  }

  String _sanitizeAndTruncateTitle(String s, int maxWords) {
    final clean = _sanitizeText(s);
    return _truncateWords(clean, maxWords);
  }

  bool _isImageFile(File f) {
    final name = f.path.toLowerCase();
    return name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.webp');
  }

  

  void _showLinkDialog() {
    final linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Agregar enlace'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'https://ejemplo.com',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (linkController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enlace agregado: ${linkController.text}'),
                    backgroundColor: const Color(0xFF5B9FED),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B9FED),
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}