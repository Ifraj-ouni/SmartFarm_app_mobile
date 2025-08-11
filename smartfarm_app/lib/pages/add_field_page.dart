import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/add_field_service.dart';
import 'package:smartfarm_app/pages/add_culture_page.dart';

class AddFieldPage extends StatefulWidget {
  //final String?  docId; // identifiant Firestore d’un champ existant (optionnel). Si présent, on modifie un champ, sinon on crée.
  //final List<LatLng>? existingPoints; //liste des points du polygone déjà enregistrés, pour pré-remplir la carte en modification.

  const AddFieldPage({super.key, required String userId});

  @override
  State<AddFieldPage> createState() => _AddFieldPageState();
}

class _AddFieldPageState extends State<AddFieldPage> {
  final MapController _mapController =
      MapController(); //final MapController _mapController = MapController();
  final AddFieldService _service = AddFieldService();
  final List<LatLng> _polygonPoints =
      []; // la liste des points définissant la forme du champ.
  String _statusLabel =
      'Touchez la carte pour ajouter des points mnimum 3 points'; //texte affiché à l’utilisateur pour guider.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    //Est-ce qu’on est en mode modification d’un terrain (avec des points déjà enregistrés) ou en mode création ?
    
  }

  void _onMapTap(LatLng point) {
    setState(() {
      //permet de reconstuire l'interface quand des données changent
      _polygonPoints.add(point); //ajoute le nouveau point cliqué a la liste
      _statusLabel =
          '${_polygonPoints.length} point(s) sélectionné(s).'; //t'affichi lel user kadeh men points séléctionna
    });
  }

  void _reset() {
    setState(() {
      _polygonPoints.clear(); //tfasakh eli majwoud f liste lkol
      _statusLabel = 'Sélection réinitialisée.'; //t'affichi lel user
    });
  }

  Future<void> _saveField() async {
    if (!mounted) return;  // éviter setState après dispose
    setState(() => _isSaving = true);
    try {
      //On appelle la méthode du service pour enregistrer
      final fieldId = await _service.saveField(_polygonPoints);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terrain enregistré avec succès.")),
      );
      if (!mounted) return;
      // 👉 Redirection vers AddCulturePage avec le nouvel ID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddCulturePage(fieldId: fieldId,),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    //null khater awel mara mafama hata point séléctionnée
    final centroid = _service.centroid(_polygonPoints);
    final area = _service.areaM2(_polygonPoints);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un terrain')),
      body: Stack(
        children: [
          //FlutterMap affiche la carte interactive.
          //Plusieurs TileLayer affichent les tuiles satellites, limites et routes.
          //Si au moins 2 points sont sélectionnés, un polygone bleu semi-transparent est dessiné.
          //Des marqueurs rouges sont affichés sur chaque point sélectionné.
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: centroid ?? const LatLng(33.8869, 9.5375),
              zoom: centroid != null ? 14 : 6,
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

          // Placé dans un Stack, ce widget sert à positionner précisément l’enfant sur l’écran.
          //Ici, il est positionné en haut de l’écran, avec des marges différentes selon que l’écran est mobile ou non.
          //Pour mobile (isMobile == true), on met 10 pixels du haut, gauche, et droite.
          //Sinon, sur tablette/desktop, 20 pixels du haut et 30 pixels des côtés.
          Positioned(
            top: isMobile ? 10 : 20,
            left: isMobile ? 10 : 30,
            right: isMobile ? 10 : 30,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LocationAutocomplete(
                  //C’est un widget personnalisé .
                  //Il affiche un champ de texte avec une liste de suggestions de lieux (autocomplete).
                  onSelected: (LatLng point) {
                    _mapController.move(
                      point,
                      14,
                    ); //Dès qu’un lieu est choisi, la carte est recentrée sur ce point avec un zoom 14.
                    //Cela permet à l’utilisateur de naviguer rapidement sur la carte en choisissant un lieu dans la recherche.
                  },
                  service: _service,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: isMobile ? 20 : 30,
            left: isMobile ? 10 : 30,
            right: isMobile ? 80 : 120,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, //on aligne tous les textes à gauche.
                  mainAxisSize: MainAxisSize
                      .min, //la colonne prend seulement la place nécessaire
                  children: [
                    Text(
                      _statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (centroid != null && _polygonPoints.length >= 3) ...[
                      Text(
                        'Centre : ${centroid.latitude.toStringAsFixed(5)}, ${centroid.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surface : ${area.toStringAsFixed(0)} m²',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: isMobile ? 20 : 30,
            right: isMobile ? 20 : 40,
            child: FloatingActionButton(
              heroTag: 'reset_polygon',
              onPressed: _isSaving ? null : _reset,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.refresh, color:Colors.white,),
            ),
          ),

          Positioned(
            bottom: isMobile ? 80 : 100,
            right: isMobile ? 20 : 40,
            child: FloatingActionButton(
              heroTag: 'save_field',
              onPressed: _isSaving ? null : _saveField,
              backgroundColor: Colors.green,
              tooltip: 'Enregistrer le terrain',
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save, color:Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationAutocomplete extends StatefulWidget {
  final void Function(LatLng) onSelected;
  final AddFieldService service;

  const LocationAutocomplete({
    required this.onSelected,
    required this.service,
    super.key,
  });

  @override
  State<LocationAutocomplete> createState() => _LocationAutocompleteState();
}

class _LocationAutocompleteState extends State<LocationAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  List<LocationSuggestion> _options = [];

  Future<void> _search(String input) async {
    final results = await widget.service.searchLocation(input);
    if (!mounted) return;  // empêcher setState si widget n’est plus monté
    setState(() {
      _options = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<LocationSuggestion>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const Iterable<LocationSuggestion>.empty();
        await _search(textEditingValue.text);
        return _options;
      },
      displayStringForOption: (LocationSuggestion option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller.value = controller.value;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Rechercher une ville',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
      onSelected: (LocationSuggestion selection) {
        widget.onSelected(LatLng(selection.lat, selection.lon));
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: options
                .map(
                  (e) => ListTile(title: Text(e.name), onTap: () => onSelected(e)),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
