import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _aiSuggestions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil de usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5B9FED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF5B9FED),
                  child: const Text(
                    'MG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dra. María González',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'maria.gonzalez@mintech.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CUENTA
          _buildSectionTitle('CUENTA'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.person_outlined,
            title: 'Información personal',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.lock_outlined,
            title: 'Privacidad y seguridad',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.language,
            title: 'Idioma',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Español',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // NOTIFICACIONES
          _buildSectionTitle('NOTIFICACIONES'),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones push',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Notificaciones por email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Sugerencias de IA',
            value: _aiSuggestions,
            onChanged: (value) {
              setState(() {
                _aiSuggestions = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // APARIENCIA
          _buildSectionTitle('APARIENCIA'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.palette_outlined,
            title: 'Tema',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Claro',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.font_download_outlined,
            title: 'Personalizar feed',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // SOPORTE
          _buildSectionTitle('SOPORTE'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Centro de ayuda',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'Contactar soporte',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Términos y condiciones',
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // Versión
          Center(
            child: Text(
              'Nexora v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '© 2025 Nexora. Todos los derechos reservados.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cerrar sesión
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 22,
              ),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Aquí iría la lógica de cerrar sesión
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF5B9FED),
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF5B9FED),
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF5B9FED),
        ),
      ),
    );
  }
}