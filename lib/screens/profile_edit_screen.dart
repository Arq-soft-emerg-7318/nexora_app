import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../services/auth_notifier.dart';
import 'home_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final Profile? profile; // if null -> create
  final String? password; // optional password to sign in after creation
  const ProfileEditScreen({Key? key, this.profile, this.password}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _direction = TextEditingController();
  final _documentNumber = TextEditingController();
  String? _selectedDocType;
  final _phone = TextEditingController();
  bool _loading = false;

  final ProfileService _service = ProfileService();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (p != null) {
      _firstName.text = p.firstName;
      _lastName.text = p.lastName;
      _email.text = p.email;
      _direction.text = p.direction ?? '';
      _documentNumber.text = p.documentNumber ?? '';
      _selectedDocType = p.documentType ?? 'DNI';
      _phone.text = p.phone ?? '';
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _direction.dispose();
    _documentNumber.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final token = auth.token;
    final profile = Profile(
      id: widget.profile?.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      direction: _direction.text.trim(),
        documentNumber: _documentNumber.text.trim(),
        documentType: _selectedDocType?.trim() ?? '',
      phone: _phone.text.trim(),
    );

    try {
      // If no profile or profile has no id, treat as creation
      if (widget.profile == null || widget.profile!.id == null) {
        // Try to create profile without token first. If server requires auth, try sign-in and retry.
        Profile created;
        try {
          created = await _service.createProfile(profile, token: token);
        } catch (e) {
          final msg = e.toString();
          if ((msg.contains('401') || msg.contains('403')) && widget.password != null && widget.password!.isNotEmpty) {
            // try sign-in and retry
            try {
              final signinOk = await auth.signIn(username: profile.email, password: widget.password!);
              if (signinOk) {
                final newToken = auth.token;
                created = await _service.createProfile(profile, token: newToken);
              } else {
                throw Exception('No se pudo iniciar sesión automáticamente');
              }
            } catch (e2) {
              throw Exception('Error creando perfil tras intentar login: ${e2.toString()}');
            }
          } else {
            rethrow;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil creado')));
        // If we haven't signed in yet but password exists, try signing in now (best-effort)
        if ((auth.token == null || auth.token!.isEmpty) && widget.password != null && widget.password!.isNotEmpty) {
          try {
            await auth.signIn(username: created.email, password: widget.password!);
          } catch (_) {}
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final ok = await _service.updateProfile(profile, token: token);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo actualizar')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null && widget.profile!.id != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar perfil' : 'Crear perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'Nombres'), validator: (v) => v==null||v.trim().isEmpty? 'Ingresa nombres':null),
              const SizedBox(height: 12),
              TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Apellidos'), validator: (v) => v==null||v.trim().isEmpty? 'Ingresa apellidos':null),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Usuario'), validator: (v) => v==null||v.trim().isEmpty? 'Ingresa email':null),
              const SizedBox(height: 12),
              TextFormField(controller: _direction, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 12),
              // Tipo de documento selector
              DropdownButtonFormField<String>(
                value: _selectedDocType ?? 'DNI',
                decoration: const InputDecoration(labelText: 'Tipo de documento'),
                items: const [
                  DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                  DropdownMenuItem(value: 'CARNET DE EXTRANJERIA', child: Text('CARNET DE EXTRANJERIA')),
                ],
                onChanged: (v) => setState(() => _selectedDocType = v),
                validator: (v) => v == null || v.isEmpty ? 'Selecciona tipo de documento' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _documentNumber, decoration: const InputDecoration(labelText: 'Número de documento')),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEditing ? 'Guardar cambios' : 'Crear perfil'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
