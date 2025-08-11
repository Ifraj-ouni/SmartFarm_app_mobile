import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  String nom = '';
  String email = '';
  String role = 'client';

  bool isLoading = false;

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'nom': nom,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur ajouté avec succès !')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un utilisateur'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nom
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (val.trim().length < 3) {
                    return 'Le nom est trop court';
                  }
                  return null;
                },
                onSaved: (val) => nom = val!.trim(),
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Adresse email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'L\'email est requis';
                  }
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(val.trim())) {
                    return 'Email invalide';
                  }
                  return null;
                },
                onSaved: (val) => email = val!.trim(),
              ),
              const SizedBox(height: 20),

              // Rôle dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Rôle',
                  prefixIcon: const Icon(Icons.admin_panel_settings),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: role,
                items: const [
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      role = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 40),

              // Bouton Ajouter
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    isLoading ? 'Ajout en cours...' : 'Ajouter l\'utilisateur',
                    style: theme.textTheme.labelLarge!.copyWith(fontSize: 18),
                  ),
                  onPressed: isLoading ? null : _addUser,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
