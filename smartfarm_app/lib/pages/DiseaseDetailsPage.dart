import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartfarm_app/pages/DiseaseSimilarDetailsPage.dart';
import 'package:smartfarm_app/pages/DiseaseTreatmentPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiseaseDetailsPage extends StatefulWidget {
  final String diseaseKey;
  final double confidence;
  final String diseaseName;
  final String imageUrl;

  const DiseaseDetailsPage({
    super.key,
    required this.diseaseKey,
    required this.confidence,
    required this.diseaseName, 
    required this.imageUrl,
  });

  @override
  State<DiseaseDetailsPage> createState() => _DiseaseDetailsPageState();
}

class _DiseaseDetailsPageState extends State<DiseaseDetailsPage> {
  final FlutterTts _tts = FlutterTts();
  Map<String, dynamic>? _data;
  Map<String, bool> _selectedSymptoms = {};
  bool _isLoading = true;
  String? _idMaladie;
  bool? _feedback; // null = pas encore voté, true = 👍, false = 👎

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadDiseaseData();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
  }

  void _handleFeedback(bool value) async {
    if (_feedback != null) return;

    setState(() {
      _feedback = value;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maladies')
          .where('nom_anglais', isEqualTo: widget.diseaseKey)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final maladieDoc = querySnapshot.docs.first;
      final maladieId = maladieDoc.id;

      await FirebaseFirestore.instance.collection('feedback_maladies').add({
        'id_user': user.uid,
        'id_maladie': maladieId,
        'feedback': value ? 'like' : 'dislike',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Merci pour votre retour positif !'
                : 'Merci pour votre retour, nous améliorerons cela.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Erreur lors de l'enregistrement du feedback : $e");
    }
  }

Future<void> _loadDiseaseData() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('maladies')
        .where('nom_anglais', isEqualTo: widget.diseaseKey)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final maladieDoc = querySnapshot.docs.first;
      final data = maladieDoc.data();

      final symptomes = (data['symptomes'] ?? '') as String;
      final symptomeList = symptomes.split(',').map((s) => s.trim()).toList();
      _selectedSymptoms = {for (var s in symptomeList) s: false}; // ✅ ici

      setState(() {
        _data = data;
        _idMaladie = maladieDoc.id;
        _isLoading = false;
      });
    } else {
      setState(() {
        _data = {};
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Erreur Firestore : $e');
    setState(() {
      _data = {};
      _isLoading = false;
    });
  }
}


  Future<void> _speakAll() async {
    if (_data == null) return;
    final txt = """
Maladie détectée : ${_data!['nom_francais'] ?? widget.diseaseKey}.
Symptômes : ${_data!['symptomes'] ?? 'Non précisés'}.
Taux de confiance : ${widget.confidence.toStringAsFixed(1)} %.
""";
    await _tts.stop();
    await _tts.speak(txt);
  }

  void _shareDiseaseInfo() {
    if (_data == null) return;
    final String info = '''
 Maladie détectée : ${_data!['nom_francais'] ?? widget.diseaseKey}
 Symptômes : ${_data!['symptomes'] ?? 'Non précisés'}
 Traitement recommandé : ${_data!['traitement'] ?? 'Non spécifié'}
 Taux de confiance : ${widget.confidence.toStringAsFixed(1)} %

 Partagé depuis SmartFarm.
''';
    Share.share(info);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nameFr = _data?['nom_francais'] ?? widget.diseaseKey;
    final description = _data?['description'] ?? 'Description indisponible.';
    final symptomes = _data?['symptomes'] ?? 'Symptômes non renseignés.';
    final traitement = _data?['traitement'] ?? 'Traitement non spécifié.';
    final type = _data?['type'] ?? 'Type inconnu';
    final imageUrl = _data?['image_url'] ?? '';

    return Scaffold(
      //backgroundColor: Colors.grey.shade100,
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadDiseaseData,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareDiseaseInfo,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () {
  final symptomesCoches = _selectedSymptoms.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DiseaseTreatmentPage(
        nomMaladie: nameFr,
        traitement: traitement,
        idMaladie: _idMaladie!,
        imageUrl: widget.imageUrl,
        symptomesCoches: symptomesCoches, // ✅ Ajouté
        feedback: _feedback,
      ),
    ),
  );
},

          icon: const Icon(Icons.check_circle_outline),
          label: const Text("Passer au traitement"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text("Image non disponible"),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                nameFr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type : $type',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _speakAll,
                        icon: const Icon(Icons.volume_up, size: 20),
                        label: const Text("Tout écouter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        avatar: const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          '${widget.confidence.toStringAsFixed(1)} %',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.confidence / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    ' Symptômes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => _tts.speak("Symptômes : $symptomes"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                symptomes,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              _sectionCard(' Description', description),
              _symptomChecklist(),
              _suggestionsSection(),
              const SizedBox(height: 24),
              const Text(
                "Cette prédiction vous semble-t-elle correcte ?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_feedback == null) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.thumb_up,
                        size: 30,
                        color: Colors.grey,
                      ),
                      onPressed: () => _handleFeedback(true),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.thumb_down,
                        size: 30,
                        color: Colors.grey,
                      ),
                      onPressed: () => _handleFeedback(false),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  _feedback == true
                      ? "Merci pour votre retour positif !"
                      : "Merci pour votre retour, nous améliorerons cela.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _feedback == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String content) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _tts.speak("$title : $content"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _suggestionsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('maladies')
          .where('type', isEqualTo: _data?['type'])
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox();

        final docs = snapshot.data!.docs
            .where((doc) => doc['nom_anglais'] != widget.diseaseKey)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " Maladies similaires",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiseaseSimilarDetailsPage(
                            nameFr: doc['nom_francais'],
                            description: doc['description'] ?? 'Non spécifiée',
                            symptomes: doc['symptomes'] ?? 'Non précisés',
                            imageUrl: doc['image_url'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(right: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc['image_url'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  doc['image_url'],
                                  height: 60,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              doc['nom_francais'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _symptomChecklist() {
  return StatefulBuilder(
    builder: (context, setModalState) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                " Symptômes observés",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._selectedSymptoms.keys.map((symptom) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(symptom),
                  value: _selectedSymptoms[symptom],
                  onChanged: (val) {
                    setModalState(() {
                      _selectedSymptoms[symptom] = val!;
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      );
    },
  );
}

}
