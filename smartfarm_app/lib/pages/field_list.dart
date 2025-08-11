import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:smartfarm_app/pages/DiseaseSimilarDetailsPage.dart';
import 'package:smartfarm_app/pages/edit_field_page.dart';
import 'add_field_page.dart';

class FieldList extends StatefulWidget {
  const FieldList({super.key});

  @override
  State<FieldList> createState() => _FieldListState();
}

class _FieldListState extends State<FieldList> {
  static const Color primaryGreen = Color(0xFF388E3C);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color beige = Color(0xFFFFF8E1);
  static const Color brown = Color(0xFF5D4037);

  final Map<String, String> _cityCache = {};

  Future<String> _getCityFromLatLon(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
    if (_cityCache.containsKey(key)) return _cityCache[key]!;

    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'smartfarm_app'})
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['address'] as Map<String, dynamic>?;

        const keysPriority = [
          'suburb',
          'neighbourhood',
          'quarter',
          'city_district',
          'city',
          'town',
          'village',
          'municipality',
          'county',
          'state',
          'region',
          'country',
        ];

        for (var k in keysPriority) {
          if (address != null && address.containsKey(k)) {
            final place = address[k];
            _cityCache[key] = place;
            return place;
          }
        }
        final disp = data['display_name'];
        if (disp != null) {
          _cityCache[key] = disp;
          return disp;
        }
      }
    } catch (e) {
      debugPrint('Erreur reverse geocode: $e');
    }
    _cityCache[key] = 'Ville inconnue';
    return 'Ville inconnue';
  }

  void _goToAddField() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFieldPage(userId: '')),
    );
  }

  void _modifyField(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final pts =
        (data['points'] as List<dynamic>?)
            ?.map((p) => LatLng(p['lat'] as double, p['lon'] as double))
            .toList() ??
        [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFieldPage(points: pts, fieldId: doc.id),
      ),
    );
  }

  Future<void> _deleteField(DocumentSnapshot doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce champ ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('fields')
          .doc(doc.id)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Champ supprimé')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(
        child: Text(
          'Utilisateur non connecté.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('fields')
        .where('uid_user', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();

    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Erreur : ${snap.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _EmptyState(onAdd: _goToAddField);
            }

            return Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _FieldCard(
                    doc: docs[i],
                    getCity: _getCityFromLatLon,
                    onEdit: _modifyField,
                    onDelete: _deleteField,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _goToAddField,
                    backgroundColor: primaryGreen,
                    tooltip: 'Ajouter un champ',
                    heroTag: 'add_field_fab',
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture, size: 72, color: _FieldCard.lightGreen),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'avez aucun champ enregistré.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _FieldCard.brown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _FieldCard.lightGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: _FieldCard.primaryGreen),
              label: const Text(
                'Ajouter un champ',
                style: TextStyle(color: _FieldCard.primaryGreen),
              ),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatefulWidget {
  const _FieldCard({
    required this.doc,
    required this.getCity,
    required this.onEdit,
    required this.onDelete,
  });

  final DocumentSnapshot doc;
  final Future<String> Function(double, double) getCity;
  final void Function(DocumentSnapshot) onEdit;
  final void Function(DocumentSnapshot) onDelete;

  static const primaryGreen = _FieldListState.primaryGreen;
  static const lightGreen = _FieldListState.lightGreen;
  static const beige = _FieldListState.beige;
  static const brown = _FieldListState.brown;

  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  bool isExpanded = false;
  late Map<String, dynamic> data;
  Map<String, dynamic>? cultureData;
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>> maladiesData = [];

  @override
  void initState() {
    super.initState();
    data = widget.doc.data()! as Map<String, dynamic>;
    _fetchCulture();
    _fetchWeather();
    _fetchMaladies();
  }

  void _fetchMaladies() async {
    final fieldId = widget.doc.id;

    try {
      final maladiesRefs = await FirebaseFirestore.instance
          .collection('maladies_users_champs')
          .where('id_field', isEqualTo: fieldId)
          .get();

      final List<Map<String, dynamic>> maladiesList = [];

      for (final doc in maladiesRefs.docs) {
        final idMaladie = doc['id_maladie'];
        final maladieSnap = await FirebaseFirestore.instance
            .collection('maladies')
            .doc(idMaladie)
            .get();

        if (maladieSnap.exists) {
          final maladieData = maladieSnap.data()!;
          final date = doc['date'] as Timestamp?;
          maladieData['date_detectee'] = date;
          maladiesList.add(maladieData);
        }
      }

      setState(() {
        maladiesData = maladiesList;
      });
    } catch (e) {
      debugPrint('Erreur récupération maladies: $e');
    }
  }

  void _fetchCulture() async {
    final cultureId = data['selected_culture_id'] as String?;
    if (cultureId != null) {
      final snap = await FirebaseFirestore.instance
          .collection('cultures')
          .doc(cultureId)
          .get();
      if (snap.exists) {
        setState(() {
          cultureData = snap.data();
        });
      }
    }
  }

  void _fetchWeather() async {
    final lat = data['latitude'] as double?;
    final lon = data['longitude'] as double?;
    if (lat != null && lon != null) {
      final apiKey = 'c2f8fd85ca3b757ea27297ba92f80987';
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=fr',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            weatherData = decoded;
          });
        }
      } catch (e) {
        debugPrint('Erreur météo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = data['latitude'] as double?;
    final lon = data['longitude'] as double?;
    final surf = (data['area_m2'] as num?)?.toStringAsFixed(1) ?? '-';

    final temp = weatherData?['main']?['temp'];
    final humidity = weatherData?['main']?['humidity'];

    final textColor = _FieldCard.brown.withOpacity(0.8);

    return FutureBuilder<String>(
      future: (lat != null && lon != null)
          ? widget.getCity(lat, lon)
          : Future.value('Ville inconnue'),
      builder: (_, citySnap) {
        final city = citySnap.data ?? '...';

        return GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Card(
            color: _FieldCard.beige,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _FieldCard.primaryGreen,
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _FieldCard.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Surface : $surf m²',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text('Modifier'),
                        onPressed: () => widget.onEdit(widget.doc),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Supprimer'),
                        onPressed: () => widget.onDelete(widget.doc),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(),

                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    if (cultureData != null) ...[
                      Text(
                        'Culture : ${cultureData!['nomCommun']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _FieldCard.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cultureData!['image_url'],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cultureData!['nomScientifique'],
                                  style: TextStyle(color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Chlorophylle : ${cultureData!['chlorophylle']}',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Text('Aucune culture associée.'),

                    const SizedBox(height: 12),

                    if (temp != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (weatherData?['weather'] != null &&
                              weatherData!['weather'] is List &&
                              weatherData!['weather'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                'https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png',
                                width: 32,
                                height: 32,
                              ),
                            ),
                          Text(
                            'Température : ${temp.toStringAsFixed(1)} °C',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 6),

                    if (humidity != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.water_drop,
                              color: const Color.fromARGB(255, 51, 159, 247),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Humidité : $humidity%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (maladiesData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Maladies détectées :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _FieldCard.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: maladiesData.map((maladie) {
                          // Formatage date
                          String dateFormatted = 'Date inconnue';
                          final ts = maladie['date_detectee'] as Timestamp?;
                          if (ts != null) {
                            final d = ts.toDate();
                            dateFormatted =
                                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets.zero, // retire le padding interne
                              leading: maladie['image_url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        maladie['image_url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                              title: Text(
                                maladie['nom_francais'] ?? 'Nom inconnu',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Détectée le : $dateFormatted',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DiseaseSimilarDetailsPage(
                                        nameFr: maladie['nom_francais'] ?? '',
                                        description:
                                            maladie['description'] ?? '',
                                        symptomes: maladie['symptomes'] ?? '',
                                        imageUrl: maladie['image_url'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Voir plus',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
