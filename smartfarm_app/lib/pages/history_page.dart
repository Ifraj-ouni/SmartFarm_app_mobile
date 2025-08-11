import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartfarm_app/pages/DiseaseSimilarDetailsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _historique = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistorique();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHistorique() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Aucun utilisateur connecté !");
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('maladies_users_champs')
        .where('uid_user', isEqualTo: user.uid.trim()) // filtre ici
        .orderBy('date', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final maladieId = data['id_maladie'];
      final fieldId = data['id_field'];

      final maladieSnap = await FirebaseFirestore.instance
          .collection('maladies')
          .doc(maladieId)
          .get();

      String? city;

      if (fieldId != null && fieldId.toString().isNotEmpty && fieldId != "none") {
        final fieldSnap = await FirebaseFirestore.instance
            .collection('fields')
            .doc(fieldId)
            .get();
        if (fieldSnap.exists) {
          final fieldData = fieldSnap.data();
          city = fieldData?['city'];
        }
      }

      if (maladieSnap.exists) {
        final maladieData = maladieSnap.data();

        final symptomesUser = (data['symptomes_observes'] as List<dynamic>?);
        final symptomesFinal = (symptomesUser != null && symptomesUser.isNotEmpty)
            ? symptomesUser.join(', ')
            : (maladieData?['symptomes'] ?? 'Non précisés');

        results.add({
          'docId': doc.id,
          'nom': maladieData?['nom_francais'] ?? '',
          'image': (data['image_url'] != null && data['image_url'].toString().isNotEmpty)
      ? data['image_url']  // image utilisateur prise par l'utilisateur
      : (maladieData?['image_url'] ?? ''),  // sinon image par défaut maladie
          'symptomes': symptomesFinal,
          'description': maladieData?['description'] ?? '',
          'date': data['date'].toDate(),
          'field': fieldId,
          'city': city,
        });
      }
    }

    setState(() {
      _historique = results;
      _isLoading = false;
    });
  } catch (e) {
    print('Erreur : $e');
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _supprimerHistorique(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('maladies_users_champs')
          .doc(docId)
          .delete();
      fetchHistorique();
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  void _partager(Map<String, dynamic> entry) {
    final date = DateFormat(
      'dd MMMM yyyy – HH:mm',
      'fr_FR',
    ).format(entry['date']);
    final message =
        '''
🦠 Maladie : ${entry['nom']}
📅 Date : $date
${entry['city'] != null ? '📍 Ville : ${entry['city']}\n' : ''}
📝 Symptômes : ${entry['symptomes']}
''';
    Share.share(message);
  }

  List<Map<String, dynamic>> get _filteredHistorique {
    return _historique.where((entry) {
      final query = _searchQuery.toLowerCase();
      final nom = entry['nom'].toString().toLowerCase();
      final date = DateFormat(
        'dd MMMM yyyy',
        'fr_FR',
      ).format(entry['date']).toLowerCase();
      final field = entry['field'].toString().toLowerCase();
      final city = entry['city']?.toString().toLowerCase() ?? '';
      return nom.contains(query) ||
          date.contains(query) ||
          field.contains(query) ||
          city.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom, date ou champ...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredHistorique.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 80,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Aucun résultat trouvé',
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Aucune maladie trouvée pour votre recherche.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _filteredHistorique.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredHistorique[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      entry['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    entry['nom'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'supprimer') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Confirmer la suppression',
                                            ),
                                            content: const Text(
                                              'Voulez-vous vraiment supprimer cette entrée ?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Annuler'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _supprimerHistorique(
                                                    entry['docId'],
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Supprimer'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (value == 'partager') {
                                        _partager(entry);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'supprimer',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Supprimer'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'partager',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.share,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Partager'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (entry['city'] != null)
                                          Text(
                                            '📍 Ville : ${entry['city']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry['symptomes'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '📅 ${DateFormat('dd MMMM yyyy – HH:mm', 'fr_FR').format(entry['date'])}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DiseaseSimilarDetailsPage(
                                              nameFr: entry['nom'],
                                              description:
                                                  entry['description'] ?? '',
                                              symptomes: entry['symptomes'],
                                              imageUrl: entry['image'],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
