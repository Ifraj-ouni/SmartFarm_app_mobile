import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDiseasePage extends StatefulWidget {
  const AddDiseasePage({super.key});

  @override
  State<AddDiseasePage> createState() => _AddDiseasePageState();
}

class _AddDiseasePageState extends State<AddDiseasePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomFrancaisController = TextEditingController();
  final TextEditingController _nomAnglaisController = TextEditingController();
  final TextEditingController _symptomesController = TextEditingController();
  final TextEditingController _traitementController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = 'sain';
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  /// Choisir une image depuis galerie ou caméra
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choisir depuis la galerie"),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                if (picked != null) setState(() => _selectedImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Prendre une photo"),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (picked != null) setState(() => _selectedImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Upload vers Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = "TON_CLOUD_NAME"; // 🔥 change par ton cloudName Cloudinary
    const uploadPreset = "TON_UPLOAD_PRESET"; // 🔥 change par ton uploadPreset

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = json.decode(await response.stream.bytesToString());
      return responseData['secure_url'];
    } else {
      debugPrint("Erreur Cloudinary: ${response.statusCode}");
      return null;
    }
  }

  Future<void> _ajouterMaladie() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Veuillez sélectionner une image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Upload image vers Cloudinary
      final imageUrl = await _uploadToCloudinary(_selectedImage!);
      if (imageUrl == null) throw Exception("Échec de l’upload Cloudinary");

      // 2️⃣ Sauvegarde dans Firestore
      await FirebaseFirestore.instance.collection('maladies').add({
        'nom_francais': _nomFrancaisController.text.trim(),
        'nom_anglais': _nomAnglaisController.text.trim(),
        'symptomes': _symptomesController.text.trim(),
        'traitement': _traitementController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Maladie ajoutée avec succès"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: requiredField
            ? (val) => (val == null || val.isEmpty) ? "⚠️ $label est obligatoire" : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une maladie")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(controller: _nomFrancaisController, label: "Nom français", icon: Icons.language, requiredField: true),
              _buildTextField(controller: _nomAnglaisController, label: "Nom anglais", icon: Icons.translate),
              _buildTextField(controller: _symptomesController, label: "Symptômes", icon: Icons.healing, maxLines: 2),
              _buildTextField(controller: _traitementController, label: "Traitement", icon: Icons.medical_services, maxLines: 2),
              _buildTextField(controller: _descriptionController, label: "Description", icon: Icons.description, maxLines: 2),

              const SizedBox(height: 16),

              // 📸 Bouton pour choisir l’image
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Choisir une image"),
              ),

              const SizedBox(height: 10),

              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'sain', child: Text('Sain')),
                  DropdownMenuItem(value: 'virale', child: Text('Virale')),
                  DropdownMenuItem(value: 'fongique', child: Text('Fongique')),
                  DropdownMenuItem(value: 'bactérienne', child: Text('Bactérienne')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 25),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _ajouterMaladie,
                        icon: const Icon(Icons.save),
                        label: const Text("Enregistrer"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
