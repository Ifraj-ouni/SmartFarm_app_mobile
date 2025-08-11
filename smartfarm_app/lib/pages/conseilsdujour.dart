// Widget Conseils du jour, avec design carte moderne, ombres, icônes
import 'package:flutter/material.dart';

class ConseilsDuJour extends StatelessWidget {
  final List<String> conseils = [
    "Arrosez vos plantes tôt le matin pour éviter l'évaporation rapide.",
    "Utilisez du compost naturel pour enrichir la terre.",
    "Contrôlez régulièrement la présence de parasites.",
    "Taillez les feuilles abîmées pour favoriser la croissance.",
  ];

  ConseilsDuJour({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50], // fond vert très clair
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.9),
            offset: const Offset(0, 6),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône ampoule dans cercle vert foncé
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade600.withOpacity(0.6),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Conseils du jour",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Liste des conseils sous forme de cartes individuelles avec ombre légère
          //Pourquoi ?
          //.map() renvoie un Iterable<Widget>,

          //.toList() convertit cet Iterable en List<Widget>,

          //Et children: attend une List<Widget>.
          Column(
            children: conseils
                .map(
                  (conseil) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade100.withOpacity(0.8),
                          offset: const Offset(0, 3),
                          blurRadius: 7,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            conseil,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
