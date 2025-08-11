import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartfarm_app/pages/DiseaseSimilarDetailsPage.dart';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context,'/accueil');
          },
        ),
        title: const Text('Maladies des Plantes'),
      ),

      body: Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher par nom ou type...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          // 📦 Chargement des maladies depuis Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('maladies').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucune maladie trouvée.'));
                }

                final maladies = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = data['nom_francais']?.toString().toLowerCase() ?? '';
                  final type = data['type']?.toString().toLowerCase() ?? '';

                  return nom.contains(searchQuery) || type.contains(searchQuery);
                }).toList();

                // ✅ Tri alphabétique
                maladies.sort((a, b) {
                  final nomA = (a.data() as Map<String, dynamic>)['nom_francais']?.toString().toLowerCase() ?? '';
                  final nomB = (b.data() as Map<String, dynamic>)['nom_francais']?.toString().toLowerCase() ?? '';
                  return nomA.compareTo(nomB);
                });

                if (maladies.isEmpty) {
                  return const Center(child: Text('Aucune maladie correspondante.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: maladies.length,
                  itemBuilder: (context, index) {
                    final maladie = maladies[index];
                    final data = maladie.data() as Map<String, dynamic>;

                    final typeText = data['type']?.toString().toLowerCase() ?? '';
                    IconData typeIcon;
                    Color typeColor;

                    if (typeText == 'sain') {
                      typeIcon = Icons.check_circle;
                      typeColor = Colors.green;
                    } else if (typeText == 'maladie') {
                      typeIcon = Icons.warning;
                      typeColor = Colors.red;
                    } else {
                      typeIcon = Icons.help_outline;
                      typeColor = Colors.orange;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: data['image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  data['image_url'],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 70),

                        title: Text(
                          data['nom_francais'] ?? 'Nom inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Row(
                          children: [
                            Icon(typeIcon, size: 18, color: typeColor),
                            const SizedBox(width: 6),
                            Text(
                              data['type'] ?? 'Type inconnu',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiseaseSimilarDetailsPage(
                                nameFr: data['nom_francais'] ?? 'Nom inconnu',
                                description: data['description'] ?? 'Pas de description',
                                symptomes: data['symptomes'] ?? 'Pas de symptômes',
                                imageUrl: data['image_url'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
