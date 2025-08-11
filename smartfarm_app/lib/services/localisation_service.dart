import 'dart:convert'; // Tkhalina nbaddlou fichier JSON l map fih les données
import 'package:geolocator/geolocator.dart'; // Package ykhalina n3rfou l location mtaa l utilisateur
import 'package:http/http.dart' as http; // Naamlou bih requêtes HTTP
//import 'package:flutter/foundation.dart' show kIsWeb;

class LocalisationService {
  final String apiKey = 'c2f8fd85ca3b757ea27297ba92f80987'; // Clé API OpenWeatherMap

  // 🔍 Fonction pour obtenir la position actuelle
  Future<Position?> obtenirPositionActuelle() async {
    // ✅ 1. Vérifie si le GPS est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Localisation désactivée — ouverture des réglages...");
      await Geolocator.openLocationSettings(); // Ouvre les paramètres
      return null;
    }

    // ✅ 2. Vérifie les permissions
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // ❌ Permission refusée
    if (permission == LocationPermission.denied) {
      print("❌ Permission refusée par l'utilisateur.");
      return null;
    }

    // 🚫 Permission refusée pour toujours
    if (permission == LocationPermission.deniedForever) {
      print("🚫 Permission refusée pour toujours — rediriger vers les réglages...");
      await Geolocator.openAppSettings(); // Ouvre les réglages de l'app
      return null;
    }

    // ✅ 3. Si tout est bon → récupérer la position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("📍 Position actuelle : ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      print("❌ Erreur en récupérant la position actuelle : $e");
      return null;
    }
  }

  // 🌦️ Fonction pour appeler l’API météo OpenWeatherMap
  Future<Map<String, dynamic>?> obtenirMeteo(Position position) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${position.latitude}&lon=${position.longitude}'
      '&appid=$apiKey&units=metric&lang=fr',
    );

    try {
      print("🌦 Appel météo en cours...");
      final response = await http.get(url);

      print("✅ Code HTTP : ${response.statusCode}");
      print("✅ Corps : ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Erreur API météo : ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception API météo : $e");
    }

    return null;
  }
}


