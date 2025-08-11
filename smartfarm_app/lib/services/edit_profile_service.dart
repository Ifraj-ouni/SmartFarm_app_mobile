// edit_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

class EditProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Contrôleurs (doivent être utilisés dans la page aussi)
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberOnlyController = TextEditingController();
  final bioController = TextEditingController();

  String originalName = '';
  Country selectedCountry = Country.parse('TN'); // Par défaut : Tunisie 🇹🇳

  // Fonction pour charger les données utilisateur
  Future<void> loadUserData(VoidCallback setStateCallback) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) return;

    final countryCode = data['country'] as String? ?? 'TN';
    selectedCountry = Country.parse(countryCode);

    nameController.text = data['nom'] ?? '';
    originalName = nameController.text;

    emailController.text = user.email ?? '';
    bioController.text = data['bio'] ?? '';

    final storedPhone = (data['phone'] as String?) ?? '';
    final dial = '+${selectedCountry.phoneCode}';
    if (storedPhone.startsWith(dial)) {
      phoneNumberOnlyController.text = storedPhone.substring(dial.length);
    } else {
      phoneNumberOnlyController.text = storedPhone;
    }

    setStateCallback(); // pour rebuild la page
  }

  // retourne le numéro complet avec l'indicatif
  String getFullPhone() {
    return '+${selectedCountry.phoneCode}${phoneNumberOnlyController.text.trim()}';
  }

  // Sauvegarder le profil utilisateur
  Future<void> saveProfile(GlobalKey<FormState> formKey, BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updateData = {
      'phone': getFullPhone(),
      'bio': bioController.text.trim(),
      'country': selectedCountry.countryCode,
    };

    if (nameController.text.trim() != originalName) {
      updateData['nom'] = nameController.text.trim();
    }

    await _firestore.collection('users').doc(user.uid).update(updateData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mis à jour avec succès'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
