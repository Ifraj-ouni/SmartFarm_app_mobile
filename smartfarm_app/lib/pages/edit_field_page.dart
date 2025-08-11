import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart'; // Pour LatLngBounds et FitBoundsOptions
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditFieldPage extends StatefulWidget {
  final String fieldId;

  const EditFieldPage({
    super.key,
    required this.fieldId,
    required List<LatLng> points,
  });

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends State<EditFieldPage> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LatLng> _polygonPoints = [];
  List<LatLng> _initialPolygonPoints = [];
  List<Map<String, dynamic>> _cultures = [];
  String? _selectedCultureId;
  String? _initialSelectedCultureId;
  bool _loading = true;
  String _statusLabel = 'Chargement des points...';

  @override
  void initState() {
    super.initState();
    _loadFieldPoints();
    _loadCultures();
  }

  Future<void> _loadFieldPoints() async {
    try {
      final doc = await _firestore
          .collection('fields')
          .doc(widget.fieldId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> pointsData = data['points'] ?? [];
        final loadedPoints = pointsData
            .map(
              (p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lon'] as num).toDouble(),
              ),
            )
            .toList();

        setState(() {
          _polygonPoints = loadedPoints;
          _initialPolygonPoints = List.from(loadedPoints);
          _selectedCultureId = data['selected_culture_id'];
          _initialSelectedCultureId = data['selected_culture_id'];
          _loading = false;
          _statusLabel = '';
        });

        if (loadedPoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(loadedPoints);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.fitBounds(
              bounds,
              options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
            );
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusLabel = 'Erreur de chargement : $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadCultures() async {
    final snapshot = await _firestore.collection('cultures').get();
    setState(() {
      _cultures = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'nomCommun': doc['nomCommun'],
              'nomScientifique': doc['nomScientifique'],
              'chlorophylle': doc['chlorophylle'],
              'image_url': doc['image_url'],
            },
          )
          .toList();
    });
  }

  LatLng? _centroid(List<LatLng> points) {
    if (points.isEmpty) return null;
    final lat =
        points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length;
    final lon =
        points.map((e) => e.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lon);
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _statusLabel = '${_polygonPoints.length} point(s) sélectionné(s).';
    });
  }

  void _reset() {
    setState(() {
      _polygonPoints = List.from(_initialPolygonPoints);
      _selectedCultureId = _initialSelectedCultureId;
      _statusLabel = 'État réinitialisé.';
    });

    if (_polygonPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_polygonPoints);
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    }
  }

  Future<void> _saveField() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le polygone doit avoir au moins 3 points."),
        ),
      );
      return;
    }
    if (_selectedCultureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une culture.")),
      );
      return;
    }

    final centroid = _centroid(_polygonPoints);
    if (centroid == null) return;

    final dataToSave = {
      'uid_user': user.uid,
      'latitude': centroid.latitude,
      'longitude': centroid.longitude,
      'area_m2': 0,
      'points': _polygonPoints
          .map((p) => {'lat': p.latitude, 'lon': p.longitude})
          .toList(),
      'selected_culture_id': _selectedCultureId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('fields')
          .doc(widget.fieldId)
          .update(dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terrain modifié avec succès.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier votre terrain et votre culture'),
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
                        center: _polygonPoints.isNotEmpty
                            ? _polygonPoints[0]
                            : const LatLng(33.8869, 9.5375),
                        zoom: 12,
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
                                .map(
                                  (p) => Marker(
                                    point: p,
                                    builder: (_) => const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                )
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
                                    backgroundImage: NetworkImage(
                                      culture['image_url'],
                                    ),
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
                              icon: const Icon(Icons.refresh,color: Colors.white,),
                              label: const Text('Réinitialiser'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(140, 45),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _saveField,
                              icon: const Icon(Icons.save,color: Colors.white,),
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
