import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _feedback; // null, true (👍), false (👎)

  // Données complètes des sections filtrables
  final List<Map<String, dynamic>> _allSections = [
    {
      'type': 'feature',
      'title': 'Suivi intelligent de vos champs',
      'desc': 'Suivi intelligent de vos champs.',
      'icon': Icons.star,
    },
    {
      'type': 'feature',
      'title': 'Prévisions météo personnalisées',
      'desc': 'Prévisions météo personnalisées.',
      'icon': Icons.wb_sunny,
    },
    {
      'type': 'feature',
      'title': 'Conseils adaptés à la saison',
      'desc': 'Conseils adaptés à la saison et la culture.',
      'icon': Icons.eco,
    },
    {
      'type': 'guide',
      'title': 'Créer un compte',
      'desc': 'Inscrivez-vous avec votre adresse e-mail.',
      'icon': Icons.person_add,
    },
    {
      'type': 'guide',
      'title': 'Connexion',
      'desc': 'Accédez à votre profil sécurisé.',
      'icon': Icons.login,
    },
    {
      'type': 'guide',
      'title': 'Ajouter un champ',
      'desc': 'Gérez vos terres agricoles efficacement.',
      'icon': Icons.landscape,
    },
    {
      'type': 'guide',
      'title': 'Recevoir des conseils',
      'desc': 'Obtenez des recommandations basées sur la météo et les saisons.',
      'icon': Icons.lightbulb,
    },
    {
      'type': 'faq',
      'title': "Je ne reçois pas d'e-mail de vérification.",
      'desc': "Vérifiez vos spams ou contactez notre support.",
      'icon': Icons.question_mark,
    },
    {
      'type': 'faq',
      'title': "Puis-je changer de culture après l'ajout ?",
      'desc': "Oui, dans la section Mes Champs.",
      'icon': Icons.question_mark,
    },
    {
      'type': 'faq',
      'title': "Comment fonctionne la géolocalisation ?",
      'desc': "Elle permet de personnaliser la météo de vos champs.",
      'icon': Icons.question_mark,
    },
    {
      'type': 'bug',
      'title': 'Signaler un bug',
      'desc': "Notez les étapes, capture d'écran et contactez-nous.",
      'icon': Icons.bug_report,
    },
    {
      'type': 'contact',
      'title': 'Contact Support',
      'desc': 'Contact@smartfarm.com.tn | +216 20 340 241',
      'icon': Icons.support_agent,
    },
  ];

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri.parse('mailto:Contact@smartfarm.com.tn?subject=Aide%20-%20Application%20Agricole');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir votre client mail.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer toutes les sections par le texte de recherche dans titre ou description
    final filteredSections = _allSections.where((section) {
      final query = _searchQuery.toLowerCase();
      return section['title'].toString().toLowerCase().contains(query) ||
          section['desc'].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),

            const SizedBox(height: 20),
            if (filteredSections.isEmpty)
              const Center(child: Text("Aucun résultat trouvé.")),
            for (var section in filteredSections)
              _buildSectionCard(section),

            const SizedBox(height: 30),
            _buildSection("Votre avis nous aide !", Icons.thumb_up_alt),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up,
                      color: _feedback == true ? Colors.green : Colors.grey),
                  onPressed: () => setState(() => _feedback = true),
                ),
                IconButton(
                  icon: Icon(Icons.thumb_down,
                      color: _feedback == false ? Colors.red : Colors.grey),
                  onPressed: () => setState(() => _feedback = false),
                ),
              ],
            ),
            if (_feedback != null)
              Center(
                child: Text(
                  _feedback == true
                      ? "Merci pour votre retour positif ! 🙏"
                      : "Merci pour votre retour, nous allons améliorer cela.",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Merci d'utiliser notre application ! ",
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                  Icon(Icons.eco, color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(section['icon'], color: Colors.green),
        title: Text(
          section['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(section['desc']),
        trailing: section['type'] == 'contact'
            ? ElevatedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.mail),
                label: const Text("Contacter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
