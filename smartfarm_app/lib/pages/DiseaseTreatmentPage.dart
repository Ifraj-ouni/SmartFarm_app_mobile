import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseTreatmentPage extends StatefulWidget {
  final String nomMaladie;
  final String traitement;
  final String idMaladie;
  final String imageUrl;
  final dynamic symptomesCoches;
  final bool? feedback; // 👍 ou 👎 ou null (non voté)

  const DiseaseTreatmentPage({
    super.key,
    required this.nomMaladie,
    required this.traitement,
    required this.idMaladie,
    required this.imageUrl,
    required this.symptomesCoches,
    required this.feedback,
  });

  @override
  State<DiseaseTreatmentPage> createState() => _DiseaseTreatmentPageState();
}

class _DiseaseTreatmentPageState extends State<DiseaseTreatmentPage> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _notesController = TextEditingController();
  String? noteFinale;

  void _speak() async {
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(widget.traitement);
  }

  void _shareTreatment() {
    Share.share(
      'Traitement pour ${widget.nomMaladie}:\n\n${widget.traitement}',
    );
  }

  Future<void> _showFieldSelectionDialog() async {
    setState(() {
      noteFinale = _notesController.text;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté.")),
      );
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('fields')
        .where('uid_user', isEqualTo: user.uid)
        .get();

    List<QueryDocumentSnapshot> fieldsDocs = querySnapshot.docs;

    Map<String, String> cultureNames = {};

    await Future.wait(
      fieldsDocs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final cultureId = data['selected_culture_id'] as String?;
        if (cultureId != null) {
          try {
            final cultureDoc = await FirebaseFirestore.instance
                .collection('cultures')
                .doc(cultureId)
                .get();
            if (cultureDoc.exists) {
              final cultureData = cultureDoc.data()!;
              cultureNames[doc.id] =
                  cultureData['nomCommun'] ?? "Culture inconnue";
            } else {
              cultureNames[doc.id] = "Culture inconnue";
            }
          } catch (e) {
            cultureNames[doc.id] = "Erreur chargement culture";
          }
        } else {
          cultureNames[doc.id] = "Pas de culture sélectionnée";
        }
      }),
    );

    String? selectedValue;

    // 🟡 Affichage du dialogue + récupération de la sélection
    final selectedFieldId = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 450,
                  maxWidth: 350,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Sélectionnez votre champ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Avant d’enregistrer, veuillez choisir votre champ.\n"
                        "Si vous n’avez pas de champ, sélectionnez 'Autre'.",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView(
                            children: fieldsDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final city = data['city'] ?? 'Ville inconnue';
                              final cultureName =
                                  cultureNames[doc.id] ?? "Chargement...";
                              final label = "$city - $cultureName";

                              return RadioListTile<String>(
                                title: Text(label),
                                value: doc.id,
                                groupValue: selectedValue,
                                onChanged: (value) {
                                  setState(() {
                                    selectedValue = value;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      RadioListTile<String>(
                        title: const Text("Autre"),
                        value: "autre",
                        groupValue: selectedValue,
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          ElevatedButton(
                            onPressed: selectedValue == null
                                ? null
                                : () {
                                    Navigator.pop(context, selectedValue);
                                  },
                            child: const Text("Confirmer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // 🟢 S'il a confirmé et choisi une valeur :
    if (selectedFieldId != null) {
      // Affichage d’un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final champId = selectedFieldId == "autre" ? "none" : selectedFieldId;
        final userId = user.uid;
        final maladieId = widget.idMaladie;

        await FirebaseFirestore.instance
            .collection('maladies_users_champs')
            .add({
              'uid_user': userId,
              'id_field': champId,
              'id_maladie': maladieId,
              'image_url': widget.imageUrl,
              'symptomes_observes': widget.symptomesCoches,
              'notes_utilisateur': noteFinale ?? '',
              'date': FieldValue.serverTimestamp(),
              'feedback_utilisateur': widget.feedback == true
                  ? 'like'
                  : widget.feedback == false
                  ? 'dislike'
                  : null,
            });

        if (context.mounted) {
          Navigator.pop(context); // ferme le loader
          Navigator.pushReplacementNamed(context, '/accueil'); // ✅ Redirection
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // ferme le loader
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
        }
      }
    }
  }

  void _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Traitement : ${widget.nomMaladie}',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(widget.traitement),
            if (noteFinale != null && noteFinale!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                "Notes personnelles :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(noteFinale!),
            ],
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(""),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareTreatment,
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nomMaladie,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                title: "Détails du traitement",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.traitement,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _speak,
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: const Text("Écouter"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Conseils similaires",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Vérifiez les feuilles toutes les 48h"),
              const Text("Évitez l’arrosage en soirée"),
              const Text("Favorisez la lumière naturelle"),
              const SizedBox(height: 30),
              const Text(
                "FAQ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              faqItem(
                question: "Quand répéter le traitement ?",
                answer: "Toutes les 2 semaines si les symptômes persistent.",
              ),
              faqItem(
                question: "Est-ce que le traitement est bio ?",
                answer: "Oui, approuvé pour l’agriculture biologique.",
              ),
              faqItem(
                question:
                    "Peut-on appliquer ce traitement sur toutes les cultures ?",
                answer:
                    "Ce traitement est recommandé pour les cultures sensibles mentionnées.",
              ),
              faqItem(
                question: "Y a-t-il des précautions à prendre ?",
                answer:
                    "Évitez l’application en plein soleil et portez des protections.",
              ),
              faqItem(
                question: "Combien de temps avant la récolte ?",
                answer:
                    "Respectez un délai de 7 jours avant la récolte après traitement.",
              ),
              const SizedBox(height: 20),
              _buildCard(
                title: "Mes notes personnelles",
                content: Column(
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Ajouter vos remarques ici...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          noteFinale = _notesController.text;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Note enregistrée ✅")),
                        );
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Ajouter la note"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/chatbot');
                  // TODO: Action contacter expert
                },
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: const Text(
                  "Contacter un expert",
                  style: TextStyle(color: Color.fromARGB(255, 233, 105, 1)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 199, 116),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _exportPDF,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  "Exporter en PDF",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 233, 105, 1),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _showFieldSelectionDialog,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                "Sauvgarder la maladie",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/accueil');
              },
              icon: const Icon(Icons.home, color: Colors.orange),
              label: const Text(
                "Aller à l'accueil",
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget faqItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(answer, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}
