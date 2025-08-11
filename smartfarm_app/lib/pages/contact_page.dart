import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // Lancer une URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact & Réseaux sociaux'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Réseaux Sociaux',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Facebook
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.facebook, color: Colors.white),
            ),
            title: const Text('Facebook'),
            onTap: () => _launchURL('https://www.facebook.com/smartfarm'),
          ),

          // Twitter (pas indiqué dans ta liste, on peut l'enlever ou garder)
          // Supprimé car tu n'as pas mentionné Twitter.

          // LinkedIn
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF0A66C2), // Couleur LinkedIn
              child: Icon(Icons.business, color: Colors.white),
            ),
            title: const Text('LinkedIn'),
            onTap: () => _launchURL('https://www.linkedin.com/company/smart-soft-pro'),
          ),

          // TikTok
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(Icons.music_note, color: Colors.white),
            ),
            title: const Text('TikTok'),
            onTap: () => _launchURL('https://www.tiktok.com/@smartfarm'),
          ),

          const Divider(height: 30),

          const Text(
            'Contact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Email
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Envoyez-nous un e-mail'),
            onTap: () => _launchURL('mailto:support@monapp.tn?subject=Aide%20-%20Application%20Agricole'),
          ),

          // Site Web
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Rendez-vous sur notre site web'),
            onTap: () => _launchURL('https://www.smartfarm.tn'),
          ),
        ],
      ),
    );
  }
}
