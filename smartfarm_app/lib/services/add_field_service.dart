import 'dart:convert';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFieldService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //calculer le centre géographique d'un ensemble de points
  LatLng? centroid(List<LatLng> points) {
    if (points.isEmpty) return null; //ken liste fergha nraj3ou null

    final lat =
        points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length; //moyenne des latitudes
    final lon =
        points.map((e) => e.longitude).reduce((a, b) => a + b) / points.length; //moyenne des longitudes
    return LatLng(lat, lon);
  }

  //Calculer la surface en m² du polygone défini par les points
  double areaM2(List<LatLng> points) {
    if (points.length < 3)
      return 0.0; //ken mafamech 3 points yaani surface null
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
    return areaKm2 * 1000000; // en m²
  }

  //Enregistre un nouveau terrain dans Firestore
  Future<String> saveField(List<LatLng> polygonPoints) async {
    //On récupère l’utilisateur connecté via Firebase Auth
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Vous devez être connecté pour enregistrer.");
    }

    //On calcule le centre géographique (centroid) des points du polygone via la fonction centroid.
    final centroidPoint = centroid(polygonPoints);

    //On calcule la surface en m² via la fonction areaM2
    final area = areaM2(polygonPoints);

    //Si le polygone est invalide (moins de 3 points donc centroid null ou surface 0), on lève une erreur.
    if (centroidPoint == null || area == 0) {
      throw Exception("Veuillez sélectionner au moins 3 points.");
    }


    final cityName = await getCityNameFromLatLng(centroidPoint);

    //Préparation des données à enregistrer
    final dataToSave = {
      'uid_user': user.uid,
      'latitude': centroidPoint.latitude,
      'longitude': centroidPoint.longitude,
      'area_m2': area,
      'city': cityName,
      'points': polygonPoints
          //liste des points du polygone, transformée en liste de maps {lat, lon}.
          .map((p) => {'lat': p.latitude, 'lon': p.longitude})
          .toList(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(), //horodatage automatique serveur (pour savoir quand ça a été modifié).
    };

    //On crée toujours un nouveau document (pas de mise à jour)
    final docRef = await _firestore.collection('fields').add(dataToSave);

    return docRef.id; //retourne l'id du document créé
  }


Future<String?> getCityNameFromLatLng(LatLng point) async {
  final url =
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'flutter_app'}, // obligatoire
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



  //Recherche des lieux avec l'API Nominatim OpenStreetMap
  Future<List<LocationSuggestion>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    final url =
        'https://nominatim.openstreetmap.org/search?format=json&q=$query';
    final res = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'flutter_app'}, //header obligatoire pour nominatim
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data
          .map(
            (e) => LocationSuggestion(
              name: e['display_name'],
              lat: double.parse(e['lat']),
              lon: double.parse(e['lon']),
            ),
          )
          .toList();
    } else {
      throw Exception("Erreur lors de la recherche de lieu");
    }
  }

  Future saveFieldTemp(List<LatLng> polygonPoints) async {}
}

class LocationSuggestion {
  final String name;
  final double lat;
  final double lon;
  LocationSuggestion({
    required this.name,
    required this.lat,
    required this.lon,
  });
}
