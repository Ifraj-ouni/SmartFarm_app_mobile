import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart'; // <--- ajout pour LatLngBounds
import 'package:latlong2/latlong.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class AddEditFieldPage extends StatefulWidget {
  final String? fieldId; // null = ajout
  final String userId;

  const AddEditFieldPage({
    super.key,
    this.fieldId,
    required this.userId,
    required bool isEditMode,
  });

  @override
  State<AddEditFieldPage> createState() => _AddEditFieldPageState();
}

class _AddEditFieldPageState extends State<AddEditFieldPage> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LatLng> _polygonPoints = [];
  List<Map<String, dynamic>> _cultures = [];
  String? _selectedCultureId;
  bool _loading = true;
  String _statusLabel = '';

  @override
  void initState() {
    super.initState();
    _loadCultures();
    if (widget.fieldId != null) {
      _loadFieldPoints();
    } else {
      _loading = false;
      _statusLabel = 'Dessinez un polygone pour votre nouveau champ.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(const LatLng(33.8869, 9.5375), 6);
      });
    }
  }

  Future<void> _loadCultures() async {
    final snapshot = await _firestore.collection('cultures').get();
    setState(() {
      _cultures = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'nomCommun': doc['nomCommun'],
                'nomScientifique': doc['nomScientifique'],
                'chlorophylle': doc['chlorophylle'],
                'image_url': doc['image_url'],
              })
          .toList();
    });
  }

  Future<void> _loadFieldPoints() async {
    try {
      final doc = await _firestore.collection('fields').doc(widget.fieldId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> pointsData = data['points'] ?? [];
        final loadedPoints = pointsData
            .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()))
            .toList();

        setState(() {
          _polygonPoints = loadedPoints;
          _selectedCultureId = data['selected_culture_id'];
          _loading = false;
          _statusLabel = '';
        });

        if (loadedPoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(loadedPoints);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.fitBounds(
              bounds,
              options: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
              ),
            );
          });
        }
      } else {
        setState(() {
          _statusLabel = "Champ introuvable.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusLabel = 'Erreur de chargement : $e';
        _loading = false;
      });
    }
  }

  LatLng? centroidFunc(List<LatLng> points) {
    if (points.isEmpty) return null;
    final lat = points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length;
    final lon = points.map((e) => e.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lon);
  }

  double areaM2(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    area = area.abs() / 2.0;
    const r = 6371.0;
    const d2r = pi / 180.0;
    double areaKm2 = area * pow(r * d2r, 2);
    return areaKm2 * 1000000; // m²
  }

  Future<String?> getCityNameFromLatLng(LatLng point) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'flutter_app'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        return address['suburb'] ??
            address['neighbourhood'] ??
            address['village'] ??
            address['town'] ??
            address['city'] ??
            address['municipality'] ??
            address['county'];
      }
    } catch (e) {
      print('Erreur reverse geocode: $e');
    }
    return null;
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _statusLabel = '${_polygonPoints.length} point(s) sélectionné(s).';
    });
  }

  void _reset() {
    setState(() {
      _polygonPoints.clear();
      _selectedCultureId = null;
      _statusLabel = 'Polygone réinitialisé.';
    });
    _mapController.move(const LatLng(33.8869, 9.5375), 6);
  }

  Future<void> _saveField() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez être connecté.")),
      );
      return;
    }

    final centroidPoint = centroidFunc(_polygonPoints);
    if (centroidPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez dessiner un polygone valide.")),
      );
      return;
    }
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le polygone doit avoir au moins 3 points.")),
      );
      return;
    }
    if (_selectedCultureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une culture.")),
      );
      return;
    }

    final area = areaM2(_polygonPoints);
    final cityName = await getCityNameFromLatLng(centroidPoint);

    final dataToSave = {
      'uid_user': widget.userId,
      'latitude': centroidPoint.latitude,
      'longitude': centroidPoint.longitude,
      'area_m2': area,
      'city': cityName ?? 'Ville inconnue',
      'points': _polygonPoints.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList(),
      'selected_culture_id': _selectedCultureId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.fieldId == null) {
        dataToSave['created_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('fields').add(dataToSave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nouveau champ ajouté avec succès.")),
        );
      } else {
        await _firestore.collection('fields').doc(widget.fieldId).update(dataToSave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Champ modifié avec succès.")),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la sauvegarde : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final centroidPoint = centroidFunc(_polygonPoints);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fieldId == null ? 'Ajouter un nouveau champ' : 'Modifier le champ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: screenHeight / 2,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: centroidPoint ?? const LatLng(33.8869, 9.5375),
                        zoom: centroidPoint != null ? 14 : 6,
                        onTap: (_, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.example.app',
                        ),
                        TileLayer(
                          urlTemplate:
                              'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.example.app',
                          backgroundColor: Colors.transparent,
                        ),
                        TileLayer(
                          urlTemplate:
                              'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.example.app',
                          backgroundColor: Colors.transparent,
                        ),
                        if (_polygonPoints.length >= 2)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: _polygonPoints,
                                borderColor: Colors.blue,
                                color: Colors.blue.withOpacity(.3),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        if (_polygonPoints.isNotEmpty)
                          MarkerLayer(
                            markers: _polygonPoints
                                .map((p) => Marker(
                                      point: p,
                                      builder: (_) => const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_statusLabel.isNotEmpty)
                          Text(
                            _statusLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCultureId,
                          decoration: const InputDecoration(
                            labelText: 'Sélectionnez une culture',
                            border: OutlineInputBorder(),
                          ),
                          items: _cultures.map((culture) {
                            return DropdownMenuItem<String>(
                              value: culture['id'],
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(culture['image_url']),
                                    radius: 12,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(culture['nomCommun']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCultureId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réinitialiser'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(140, 45),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _saveField,
                              icon: const Icon(Icons.save),
                              label: const Text('Enregistrer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(140, 45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
