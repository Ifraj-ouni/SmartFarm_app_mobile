import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String? selectedOption; // 'bad', 'average', 'good'
  //fonction besh tabaath l feedback lel firestore
  void _submitFeedback() async {
  if (selectedOption != null) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'avis': selectedOption,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre retour !')),
        );
        Navigator.of(context).pop(); // Fermer le dialogue après soumission tarjaa lel page eli kbalha
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du retour : $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Quelle est votre expérience avec l\'application SmartFarm?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEmojiOption('😟', 'Mauvaise', 'bad'),
                  _buildEmojiOption('😐', 'Moyenne', 'average'),
                  _buildEmojiOption('😊', 'Bonne', 'good'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedOption == null ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedOption == null ? Colors.grey[300] : Colors.green,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Soumettre'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiOption(String emoji, String label, String value) {
    final isSelected = selectedOption == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = value;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }
}
