import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDiseasePage extends StatefulWidget {
  const AddDiseasePage({super.key});

  @override
  State<AddDiseasePage> createState() => _AddDiseasePageState();
}

class _AddDiseasePageState extends State<AddDiseasePage> {
  final TextEditingController _nomFrancaisController = TextEditingController();
  final TextEditingController _nomAnglaisController = TextEditingController();
  final TextEditingController _symptomesController = TextEditingController();
  final TextEditingController _traitementController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'sain';

  Future<void> _ajouterMaladie() async {
    await FirebaseFirestore.instance.collection('maladies').add({
      'nom_francais': _nomFrancaisController.text.trim(),
      'nom_anglais': _nomAnglaisController.text.trim(),
      'symptomes': _symptomesController.text.trim(),
      'traitement': _traitementController.text.trim(),
      'image_url': _imageUrlController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
    });

    Navigator.pop(context); // Revenir à la liste après ajout
  }

  @override
  void dispose() {
    _nomFrancaisController.dispose();
    _nomAnglaisController.dispose();
    _symptomesController.dispose();
    _traitementController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une maladie")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nomFrancaisController,
              decoration: const InputDecoration(labelText: 'Nom français'),
            ),
            TextField(
              controller: _nomAnglaisController,
              decoration: const InputDecoration(labelText: 'Nom anglais'),
            ),
            TextField(
              controller: _symptomesController,
              decoration: const InputDecoration(labelText: 'Symptômes'),
              maxLines: 2,
            ),
            TextField(
              controller: _traitementController,
              decoration: const InputDecoration(labelText: 'Traitement'),
              maxLines: 2,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'sain', child: Text('Sain')),
                DropdownMenuItem(value: 'malade', child: Text('Malade')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                });
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _ajouterMaladie,
              icon: const Icon(Icons.save),
              label: const Text('Ajouter la maladie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
