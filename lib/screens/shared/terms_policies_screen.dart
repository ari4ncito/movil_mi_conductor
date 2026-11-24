import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsPoliciesScreen extends StatelessWidget {
  static const String defaultUrlTerminos = 'https://web-mi-conductor1.vercel.app/terminos-servicio';
  static const String defaultUrlPrivacidad = 'https://web-mi-conductor1.vercel.app/politica-privacidad';

  final String? urlTerminos;
  final String? urlPrivacidad;

  const TermsPoliciesScreen({
    super.key,
    this.urlTerminos,
    this.urlPrivacidad,
  });

  Future<void> _abrirUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enlace no disponible por el momento.'),
          backgroundColor: Color(0xFF0F3D44),
        ),
      );
      return;
    }
    final uri = Uri.parse(url.trim());
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback en caso de que externalApplication no responda
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No fue posible abrir el enlace: $url'),
              backgroundColor: const Color(0xFF0F3D44),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Términos y Políticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3D44),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F3D44), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDocumentCard(
                context: context,
                icon: Icons.article_rounded,
                title: 'Términos y Condiciones',
                description: 'Consulta los términos generales del servicio',
                url: urlTerminos ?? defaultUrlTerminos,
              ),
              const SizedBox(height: 14),
              _buildDocumentCard(
                context: context,
                icon: Icons.shield_rounded,
                title: 'Política de Privacidad',
                description: 'Protección de datos personales y seguridad',
                url: urlPrivacidad ?? defaultUrlPrivacidad,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    String? url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirUrl(context, url),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3D44).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF8A00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2B2F),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7C80),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
