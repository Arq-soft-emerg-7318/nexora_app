import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_notifier.dart';
import 'home_screen.dart';

class RegisterScreen2 extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const RegisterScreen2({
    Key? key,
    required this.name,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<RegisterScreen2> createState() => _RegisterScreen2State();
}

class _RegisterScreen2State extends State<RegisterScreen2> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  final _companyController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'ingeniero', 'label': 'Ingeniero de Minas', 'icon': Icons.engineering},
    {'value': 'geologo', 'label': 'Geólogo', 'icon': Icons.terrain},
    {'value': 'supervisor', 'label': 'Supervisor', 'icon': Icons.supervisor_account},
    {'value': 'seguridad', 'label': 'Seguridad', 'icon': Icons.security},
    {'value': 'operador', 'label': 'Operador', 'icon': Icons.build},
    {'value': 'otro', 'label': 'Otro', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (_formKey.currentState!.validate() && _acceptTerms && _selectedRole != null) {
      // Llamar al servicio de autenticación para crear cuenta y luego iniciar sesión
      setState(() {
        _isLoading = true;
      });
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      try {
        final ok = await auth.signUp(username: widget.email, password: widget.password);
        if (ok && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registrando: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu rol profesional'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              // Header con botón de volver
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '← Volver',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo y nombre
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 32,
                                color: const Color(0xFF5B9FED),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Nexora',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Indicador de pasos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Paso 1 - Completado
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B9FED).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Color(0xFF5B9FED),
                                  size: 20,
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 2,
                              color: const Color(0xFF5B9FED),
                            ),
                            // Paso 2 - Activo
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5B9FED),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Título
                        const Text(
                          'Información profesional',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtítulo
                        Text(
                          'Completa tu perfil profesional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Formulario
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rol profesional
                              Text(
                                'Rol profesional',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.work_outline),
                                    hintText: 'Selecciona tu rol',
                                  ),
                                  items: _roles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role['value'],
                                      child: Row(
                                        children: [
                                          Icon(role['icon'], size: 20, color: Colors.grey[600]),
                                          const SizedBox(width: 12),
                                          Text(role['label']),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor selecciona tu rol';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Empresa (opcional)
                              Text(
                                'Empresa u organización (opcional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _companyController,
                                decoration: InputDecoration(
                                  hintText: 'MinTech Solutions',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: Icon(Icons.business_outlined, color: Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Términos y condiciones
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF5B9FED),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                          children: const [
                                            TextSpan(text: 'Acepto los '),
                                            TextSpan(
                                              text: 'Términos y Condiciones',
                                              style: TextStyle(
                                                color: Color(0xFF5B9FED),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(text: ' y la '),
                                            TextSpan(
                                              text: 'Política de Privacidad',
                                              style: TextStyle(
                                                color: Color(0xFF5B9FED),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(text: ' de Nexora. También acepto recibir contenido personalizado y sugerencias de la IA.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Botón crear cuenta
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _completeRegistration,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Crear cuenta',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Beneficios de Nexora
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Beneficios de Nexora',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildBenefit(
                                      'Contenido curado por IA según tus intereses profesionales',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBenefit(
                                      'Conexión con profesionales del sector minero global',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBenefit(
                                      'Acceso a investigaciones, tendencias y recursos exclusivos',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF5B9FED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
