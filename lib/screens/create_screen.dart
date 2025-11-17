import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../services/auth_notifier.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();

  // category name -> id mapping (sample ids). Ajusta más tarde con endpoint real.
  final Map<String, int> _categoryMap = {
    'Pontones': 1,
    'Innovación': 2,
    'Seguridad': 3,
    'Geología': 4,
    'Sostenibilidad': 5,
  };

  String _selectedCategory = 'Pontones';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para publicar
                if (_contentController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Publicación creada exitosamente'),
                      backgroundColor: Color(0xFF5B9FED),
                    ),
                  );
                  _contentController.clear();
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Publicar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B9FED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 0,
              ),
            ),
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

            // CommunityId opcional
            const Text(
              'Community ID (opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _communityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Dejar vacío si no aplica',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            if (_selectedFile != null)
              Text('Archivo: ${_selectedFile!.path.split('/').last}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 18),
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
      int? communityId;
      if (_communityController.text.trim().isNotEmpty) {
        communityId = int.tryParse(_communityController.text.trim());
      }

      final Map<String, dynamic> postObj = {
        'title': title,
        'authorId': null,
        'body': body,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: const Color(0xFF5B9FED),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Asistente IA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El asistente de IA puede ayudarte a:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            _buildAIFeature('✨ Mejorar la redacción de tu contenido'),
            _buildAIFeature('📝 Generar títulos atractivos'),
            _buildAIFeature('🎯 Sugerir hashtags relevantes'),
            _buildAIFeature('🔍 Optimizar para búsquedas'),
            _buildAIFeature('💡 Proponer ideas de contenido'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generando sugerencias con IA...'),
                  backgroundColor: Color(0xFF5B9FED),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B9FED),
            ),
            child: const Text('Usar IA'),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
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