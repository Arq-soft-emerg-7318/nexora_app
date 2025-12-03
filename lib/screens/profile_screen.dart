import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../services/auth_notifier.dart';
import 'profile_edit_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      final token = auth.token;
      final storedId = await _service.getStoredProfileId();
      if (storedId != null) {
        final p = await _service.fetchById(storedId, token: token);
        setState(() => _profile = p);
      } else {
        setState(() => _error = 'No hay perfil creado.');
      }
    } catch (e) {
      setState(() => _error = 'Error cargando perfil');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onEdit() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileEditScreen(profile: _profile)));
    if (result == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 48, child: Text(_profile!.firstName.isNotEmpty ? _profile!.firstName[0].toUpperCase() : '?')),
                      const SizedBox(height: 12),
                      Text('${_profile!.firstName} ${_profile!.lastName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_profile!.email, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.location_on_outlined, _profile!.direction ?? '—'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.badge_outlined, _profile!.documentNumber ?? '—'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone_outlined, _profile!.phone ?? '—'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar perfil'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final auth = Provider.of<AuthNotifier>(context, listen: false);
                            await auth.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700]))),
      ],
    );
  }
}