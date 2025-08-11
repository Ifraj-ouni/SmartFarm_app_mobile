import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CulturesPage extends StatefulWidget {
  const CulturesPage({super.key});

  @override
  State<CulturesPage> createState() => _CulturesPageState();
}

class _CulturesPageState extends State<CulturesPage> {
  String searchQuery = '';
  bool showPendingOnly = false;
  bool hasPendingCultures = false;

  File? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkPendingCultures();
  }

  Future<void> _checkPendingCultures() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cultures')
        .where('add_by_user', isEqualTo: false)
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        hasPendingCultures = snapshot.docs.isNotEmpty;
      });
    }
  }

  // Upload image vers Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dx1zihwal'; // <-- Mets ton cloud name ici
    final uploadPreset = 'fe3mrlpw'; // <-- Mets ton upload preset ici

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      final Map<String, dynamic> resJson = json.decode(resStr);

      if (response.statusCode == 200) {
        return resJson['secure_url'] as String?;
      } else {
        debugPrint('Erreur upload Cloudinary: $resStr');
        return null;
      }
    } catch (e) {
      debugPrint('Exception upload Cloudinary: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Recherche
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher une culture',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),

          // Bouton Ajouter une culture (toujours visible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddCultureDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Ajouter une culture',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // Bouton "Cultures en attente" (visible si cultures en attente OU si on est en mode attente)
          if (hasPendingCultures || showPendingOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showPendingOnly = !showPendingOnly;
                    });
                  },
                  icon: Icon(
                    showPendingOnly ? Icons.list : Icons.hourglass_bottom,
                    color: Colors.white,
                  ),
                  label: Text(
                    showPendingOnly
                        ? 'Afficher toutes les cultures'
                        : 'Cultures en attente',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        showPendingOnly ? Colors.grey : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // Liste des cultures
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cultures')
                  .orderBy('nomCommun')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cultures = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom =
                      (data['nomCommun'] ?? '').toString().toLowerCase();
                  final containsQuery = nom.contains(searchQuery);

                  if (showPendingOnly) {
                    return containsQuery && data['add_by_user'] == false;
                  } else {
                    return containsQuery &&
                        (!data.containsKey('add_by_user') ||
                            data['add_by_user'] == true);
                  }
                }).toList();

                if (cultures.isEmpty) {
                  return const Center(child: Text('Aucune culture trouvée'));
                }

                return ListView.builder(
                  itemCount: cultures.length,
                  itemBuilder: (context, index) {
                    final doc = cultures[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nomCommun = data['nomCommun'] ?? 'Inconnu';
                    final nomScientifique = data['nomScientifique'] ?? '';
                    final chlorophylle = data['chlorophylle'] ?? '';
                    final imageUrl = data['image_url'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.local_florist, size: 40),
                        title: Text(nomCommun),
                        subtitle: Text(nomScientifique.isNotEmpty
                            ? nomScientifique
                            : 'Nom scientifique non disponible'),
                        trailing: showPendingOnly
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () {
                                      _showValidationDialog(doc);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                    onPressed: () {
                                      _confirmDelete(doc.id);
                                    },
                                  ),
                                ],
                              )
                            : Text(
                                chlorophylle.isNotEmpty
                                    ? 'Chl: $chlorophylle'
                                    : '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
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

  void _showAddCultureDialog() {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController sciController = TextEditingController();
    final TextEditingController chloroController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvelle culture'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom commun'),
                ),
                TextField(
                  controller: sciController,
                  decoration:
                      const InputDecoration(labelText: 'Nom scientifique'),
                ),
                TextField(
                  controller: chloroController,
                  decoration:
                      const InputDecoration(labelText: 'Chlorophylle'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setStateDialog(() {
                        _pickedImage = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Choisir une image"),
                ),
                if (_pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(
                      _pickedImage!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickedImage = null;
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (nomController.text.trim().isEmpty) return;

                      setStateDialog(() {
                        _isUploading = true;
                      });

                      String imageUrl = '';

                      if (_pickedImage != null) {
                        final url = await _uploadImageToCloudinary(_pickedImage!);
                        if (url != null) {
                          imageUrl = url;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Erreur lors de l'upload de l'image.")),
                          );
                        }
                      }

                      await FirebaseFirestore.instance.collection('cultures').add({
                        'nomCommun': nomController.text.trim(),
                        'nomScientifique': sciController.text.trim(),
                        'chlorophylle': chloroController.text.trim(),
                        'add_by_user': true, // validée directement
                        'image_url': imageUrl,
                        'created_at': FieldValue.serverTimestamp(),
                      });

                      _pickedImage = null;
                      setStateDialog(() {
                        _isUploading = false;
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Culture ajoutée avec succès.")),
                      );
                      _checkPendingCultures();
                    },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette culture ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('cultures')
                  .doc(docId)
                  .delete();
              _checkPendingCultures();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Culture supprimée.')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showValidationDialog(DocumentSnapshot doc) {
    final TextEditingController chlorophylleController =
        TextEditingController();
    final TextEditingController nomScientifiqueController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la culture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomScientifiqueController,
              decoration: const InputDecoration(labelText: 'Nom scientifique'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: chlorophylleController,
              decoration: const InputDecoration(labelText: 'Chlorophylle'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('cultures')
                  .doc(doc.id)
                  .update({
                'add_by_user': true,
                'nomScientifique': nomScientifiqueController.text.trim(),
                'chlorophylle': chlorophylleController.text.trim(),
              });
              Navigator.pop(context);
              _checkPendingCultures();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Culture validée.')),
              );
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
