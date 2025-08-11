import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart'; 

class DiseaseSimilarDetailsPage extends StatefulWidget {
  final String nameFr;
  final String description;
  final String symptomes;
  final String imageUrl;

  const DiseaseSimilarDetailsPage({
    super.key,
    required this.nameFr,
    required this.description,
    required this.symptomes,
    required this.imageUrl,
  });

  @override
  State<DiseaseSimilarDetailsPage> createState() => _DiseaseSimilarDetailsPageState();
}

class _DiseaseSimilarDetailsPageState extends State<DiseaseSimilarDetailsPage> {
  final FlutterTts _tts = FlutterTts();
  String? _type;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchDiseaseType();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
  }

  Future<void> _fetchDiseaseType() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('maladies')
          .where('nom_francais', isEqualTo: widget.nameFr)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _type = query.docs.first.data()['type'];
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération du type : $e");
    }
  }

  Future<void> _speakAll() async {
    final fullText =
        "Maladie : ${widget.nameFr}. Symptômes : ${widget.symptomes}. Description : ${widget.description}. Type : ${_type ?? 'inconnu'}.";
    await _tts.stop();
    await _tts.speak(fullText);
  }

  void _shareDiseaseInfo() {
    final content = '''
🌿 Maladie : ${widget.nameFr}
📌 Type : ${_type ?? 'inconnu'}
🧪 Symptômes : ${widget.symptomes}
📝 Description : ${widget.description}
''';
    Share.share(content);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Pas de titre
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDiseaseInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                widget.nameFr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800], // 🎨 Couleur personnalisée ici
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_type != null)
              Text(
                "Type : $_type",
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: _speakAll,
                icon: const Icon(Icons.volume_up),
                label: const Text("Tout écouter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Symptômes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _tts.speak("Symptômes : ${widget.symptomes}"),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(widget.symptomes, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _tts.speak("Description : ${widget.description}"),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(widget.description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
