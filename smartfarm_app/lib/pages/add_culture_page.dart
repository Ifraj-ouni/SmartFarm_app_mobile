import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddCulturePage extends StatefulWidget {
  final String fieldId;

  const AddCulturePage({super.key, required this.fieldId});

  @override
  State<AddCulturePage> createState() => _AddCulturePageState();
}

class _AddCulturePageState extends State<AddCulturePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newCultureController = TextEditingController();

  List<DocumentSnapshot> _allCultures = [];
  List<DocumentSnapshot> _filteredCultures = [];

  String? _currentlyAdding;
  bool _hasCultureAlready = false;
  bool _cultureAssigned = false; // ✅ nouveau booléen
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _fetchCultures();
    _searchController.addListener(_filterCultures);
    _checkIfCultureExists();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCultures);
    _searchController.dispose();
    _newCultureController.dispose();

    // ✅ Supprimer le champ s'il n'a pas de culture associée
    if (!_cultureAssigned) {
      FirebaseFirestore.instance.collection('fields').doc(widget.fieldId).delete();
    }

    super.dispose();
  }

  Future<void> _fetchCultures() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('cultures').get();
    setState(() {
      _allCultures = snapshot.docs;
      _filteredCultures = _allCultures;
    });
  }

  void _filterCultures() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCultures = _allCultures.where((doc) {
        final nom = (doc['nomCommun'] ?? '').toString().toLowerCase();
        final sci = (doc['nomScientifique'] ?? '').toString().toLowerCase();
        return nom.contains(query) || sci.contains(query);
      }).toList();
    });
  }

  Future<bool> _cultureExistsForField() async {
    final field = await FirebaseFirestore.instance
        .collection('fields')
        .doc(widget.fieldId)
        .get();
    return field.data()?['selected_culture_id'] != null;
  }

  void _checkIfCultureExists() async {
    final exists = await _cultureExistsForField();
    setState(() {
      _hasCultureAlready = exists;
    });
  }

  Future<void> _selectCulture(DocumentSnapshot cultureDoc) async {
    if (_currentlyAdding != null) return;

    setState(() => _currentlyAdding = cultureDoc.id);

    try {
      final alreadyExists = await _cultureExistsForField();
      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Une culture est déjà associée à ce champ."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('fields')
          .doc(widget.fieldId)
          .update({'selected_culture_id': cultureDoc.id});

      _cultureAssigned = true; // ✅ Culture sélectionnée → ne pas supprimer le champ

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Culture "${cultureDoc['nomCommun']}" associée au champ !'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushNamedAndRemoveUntil(context, '/field', (route) => false);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _currentlyAdding = null);
    }
  }

  Future<File?> _pickImageFromSource(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> _showImageSourceOptions() async {
    return showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisir une source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  final file = await _pickImageFromSource(ImageSource.camera);
                  Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Depuis la galerie'),
                onTap: () async {
                  final file = await _pickImageFromSource(ImageSource.gallery);
                  Navigator.pop(context, file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCultureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFFF0FDF4),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.eco, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text('Ajouter une culture',
                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _newCultureController,
                      decoration: InputDecoration(
                        labelText: 'Nom de la culture',
                        prefixIcon:
                            const Icon(Icons.grass, color: Color(0xFF4CAF50)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await _showImageSourceOptions();
                        if (picked != null) {
                          setStateDialog(() {
                            _pickedImage = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo, color: Colors.white),
                      label: const Text('Ajouter une image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_pickedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _pickedImage!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _pickedImage = null;
                    _newCultureController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createCulture();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createCulture() async {
    final nom = _newCultureController.text.trim();
    if (nom.isEmpty || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/dx1zihwal/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'fe3mrlpw'
        ..files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final Map<String, dynamic> resData = json.decode(resStr);

        final imageUrl = resData['secure_url'];

        await FirebaseFirestore.instance.collection('cultures').add({
          'nomCommun': nom,
          'image_url': imageUrl,
          'add_by_user': false,
          'nomScientifique': '',
          'chlorophylle': '',
          'created_at': FieldValue.serverTimestamp(),
        });

        _pickedImage = null;
        _newCultureController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Culture "$nom" créée et en attente de validation.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erreur upload Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ajouter une culture'),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddCultureDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nouvelle culture',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hasCultureAlready)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Une culture est déjà ajoutée pour ce champ.',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCultures.length,
              itemBuilder: (context, index) {
                final doc = _filteredCultures[index];
                final isLoading = _currentlyAdding == doc.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Image.network(
                          doc['image_url'],
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['nomCommun'] ?? '',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doc['nomScientifique'] ?? '',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Chlorophylle: ${doc['chlorophylle'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Color(0xFF4E944F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7FA05D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                          ),
                          onPressed: (isLoading || _hasCultureAlready)
                              ? null
                              : () => _selectCulture(doc),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
