import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_disease_page.dart';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});

  @override
  State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  String _searchText = '';

  void _showEditDiseaseDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final nomFrController = TextEditingController(text: data['nom_francais']);
    final nomAnController = TextEditingController(text: data['nom_anglais']);
    final symptController = TextEditingController(text: data['symptomes']);
    final traitController = TextEditingController(text: data['traitement']);
    final imageController = TextEditingController(text: data['image_url']);
    final descController = TextEditingController(text: data['description']);
    String selectedType = data['type'] ?? 'sain';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier la maladie"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomFrController,
                decoration: const InputDecoration(labelText: 'Nom français'),
              ),
              TextField(
                controller: nomAnController,
                decoration: const InputDecoration(labelText: 'Nom anglais'),
              ),
              TextField(
                controller: symptController,
                decoration: const InputDecoration(labelText: 'Symptômes'),
                maxLines: 2,
              ),
              TextField(
                controller: traitController,
                decoration: const InputDecoration(labelText: 'Traitement'),
                maxLines: 2,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'sain', child: Text('Sain')),
                  DropdownMenuItem(value: 'malade', child: Text('Malade')),
                ],
                onChanged: (val) => selectedType = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('maladies')
                  .doc(doc.id)
                  .update({
                    'nom_francais': nomFrController.text.trim(),
                    'nom_anglais': nomAnController.text.trim(),
                    'symptomes': symptController.text.trim(),
                    'traitement': traitController.text.trim(),
                    'image_url': imageController.text.trim(),
                    'description': descController.text.trim(),
                    'type': selectedType,
                  });
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Supprimer cette maladie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('maladies')
                  .doc(doc.id)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher une maladie',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDiseasePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  label: const Text(
                    "Ajouter une maladie",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maladies')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nom = data['nom_francais']?.toLowerCase() ?? '';
                return nom.contains(_searchText);
              }).toList();

              filteredDocs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final typeCompare = (dataA['type'] ?? '').compareTo(
                  dataB['type'] ?? '',
                );
                if (typeCompare != 0) return typeCompare;
                return (dataA['nom_francais'] ?? '').compareTo(
                  dataB['nom_francais'] ?? '',
                );
              });

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image_url'] ?? '',
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              height: 60,
                              width: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['nom_francais'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['symptomes'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: data['type'] == 'malade'
                                      ? Colors.red[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data['type'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: data['type'] == 'malade'
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // 👍👎 Likes/Dislikes
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('feedback_maladies')
                                    .where('id_maladie', isEqualTo: doc.id)
                                    .snapshots(),
                                builder: (context, fbSnapshot) {
                                  if (!fbSnapshot.hasData)
                                    return const SizedBox();
                                  final feedbackDocs = fbSnapshot.data!.docs;
                                  final likeCount = feedbackDocs
                                      .where(
                                        (f) =>
                                            (f.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['feedback'] ==
                                            'like',
                                      )
                                      .length;
                                  final dislikeCount = feedbackDocs
                                      .where(
                                        (f) =>
                                            (f.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['feedback'] ==
                                            'dislike',
                                      )
                                      .length;

                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.thumb_up,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(likeCount.toString()),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.thumb_down,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(dislikeCount.toString()),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'modifier') {
                              _showEditDiseaseDialog(doc);
                            } else if (value == 'supprimer') {
                              _showDeleteConfirmation(doc);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'modifier',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'supprimer',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
