import 'package:flutter/material.dart';

class Partenaire {
  final String nom;
  final String description;
  final String logoUrl;

  Partenaire({
    required this.nom,
    required this.description,
    required this.logoUrl,
  });
}

class PartenairesPage extends StatelessWidget {
  PartenairesPage({super.key});

  final List<Partenaire> partenaires = [
    Partenaire(
      nom: "Google",
      description: "Leader mondial des technologies et moteur de recherche.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg",
    ),
    Partenaire(
      nom: "Microsoft",
      description: "Entreprise multinationale spécialisée dans l'informatique et logiciels.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/4/44/Microsoft_logo.svg",
    ),
    Partenaire(
      nom: "Amazon",
      description: "Géant du commerce électronique et du cloud computing.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/a/a9/Amazon_logo.svg",
    ),
    Partenaire(
      nom: "Facebook (Meta)",
      description: "Leader des réseaux sociaux et des technologies immersives.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png",
    ),
    Partenaire(
      nom: "IBM",
      description: "Entreprise pionnière en informatique et intelligence artificielle.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/5/51/IBM_logo.svg",
    ),
    Partenaire(
      nom: "Tesla",
      description: "Innovateur dans les voitures électriques et énergies renouvelables.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/b/bd/Tesla_Motors.svg",
    ),
    Partenaire(
      nom: "Airbnb",
      description: "Plateforme de location de logements entre particuliers.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/6/69/Airbnb_Logo_Bélo.svg",
    ),
    Partenaire(
      nom: "Samsung",
      description: "Multinationale sud-coréenne spécialisée en électronique grand public.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg",
    ),
    Partenaire(
      nom: "Netflix",
      description: "Leader mondial du streaming vidéo et production de contenu.",
      logoUrl: "https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Nos partenaires'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: partenaires.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final partenaire = partenaires[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    partenaire.logoUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 60),
                  ),
                ),
                title: Text(
                  partenaire.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  partenaire.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
