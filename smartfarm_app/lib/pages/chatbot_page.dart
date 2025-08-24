import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartfarm_app/pages/DiseaseSimilarDetailsPage.dart';
import 'package:smartfarm_app/pages/conseilsdujour.dart';
import '../services/localisation_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> with WidgetsBindingObserver {
  final localisationService = LocalisationService();

  String temperature = '';
  String description = '';
  String ville = '';
  String icon = '';
  String humidity = '';
  double vitesseVentMS = 0.0;
  double vitesseVentKMH = 0.0;
  String heureDuLever = '';
  String heureDuCoucher = '';
  String userName = '';
  String userImageUrl = '';

  List<Map<String, dynamic>> maladiesData = [];

  Future<void> fetchUserMaladies() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('maladies_users_champs')
          .where('uid_user', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> tempMaladies = [];

      for (final doc in snapshot.docs) {
        final idMaladie = doc['id_maladie'];
        final maladieDoc = await FirebaseFirestore.instance
            .collection('maladies')
            .doc(idMaladie)
            .get();

        if (maladieDoc.exists) {
          final maladieData = maladieDoc.data()!;
          // Ajout de la date détectée à la map maladie
          tempMaladies.add({
            ...maladieData,
            'date_detectee': doc['date'], // Timestamp Firestore
            'image_url': (doc['image_url'] != null && doc['image_url'].toString().isNotEmpty)
      ? doc['image_url']
      : (maladieData['image_url'] ?? ''),
            
          });
        }
      }

      setState(() {
        maladiesData = tempMaladies;
      });
    } catch (e) {
      print('Erreur chargement maladies: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['nom'] ?? 'Utilisateur';
          userImageUrl =
              userDoc['avatar'] ?? ''; // <- 🔥 ici tu charges l'image
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    obtenirMeteoActuelle();
    fetchUserMaladies();
    _loadUserData();
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      obtenirMeteoActuelle();
    }
  }

  Future<void> obtenirMeteoActuelle() async {
    final position = await localisationService.obtenirPositionActuelle();

    if (!mounted) return; // ✅ ← Ajoute ceci après chaque 'await'

    if (position != null) {
      final meteo = await localisationService.obtenirMeteo(position);

      if (!mounted) return; // ✅ ← Encore ici après un autre 'await'

      if (meteo != null) {
        final int sunriseTimestamp = meteo['sys']['sunrise'];
        final int sunsetTimestamp = meteo['sys']['sunset'];

        final DateTime sunrise = DateTime.fromMillisecondsSinceEpoch(
          sunriseTimestamp * 1000,
          isUtc: true,
        ).toLocal();
        final DateTime sunset = DateTime.fromMillisecondsSinceEpoch(
          sunsetTimestamp * 1000,
          isUtc: true,
        ).toLocal();

        final String heureLever = DateFormat.Hm('fr_FR').format(sunrise);
        final String heureCoucher = DateFormat.Hm('fr_FR').format(sunset);

        if (!mounted) return; // ✅ Avant chaque setState

        setState(() {
          temperature = "${meteo['main']['temp']} °C";
          description = meteo['weather'][0]['main'];
          icon = meteo['weather'][0]['icon'];
          ville = meteo['name'];
          humidity = "${meteo['main']['humidity']} %";
          vitesseVentMS = meteo['wind']['speed'];
          vitesseVentKMH = vitesseVentMS * 3.6;
          heureDuLever = heureLever;
          heureDuCoucher = heureCoucher;
        });
      } else {
        if (!mounted) return;
        setState(() {
          temperature = 'Erreur météo';
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        temperature = 'Localisation désactivée';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nom de l'application à gauche
            const Text(
              'AgriScan',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),

            // Nom + image de l'utilisateur à droite
            Row(
              children: [
                // Nom de l'utilisateur
                Text(
                  userName.isNotEmpty ? userName : 'Chargement...',
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8), // espace entre nom et image
                // Photo de profil
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: userImageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(userImageUrl)
                      : const AssetImage('images/default_avatar.jpg')
                            as ImageProvider,
                  child: userImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),

      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/chatbot',
          ); // 🔁 redirige vers la page chatbot
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // ───── Section "Soignez votre culture" ─────
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Soignez votre culture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Image.asset(
                                'images/photo.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Prenez\nune photo',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Column(
                            children: [
                              Image.asset(
                                'images/diagnostic.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Lisez le\ndiagnostic',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Column(
                            children: [
                              Image.asset(
                                'images/traitement.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Obtenez le\ntraitement',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 19,
                          ),
                          label: const Text(
                            'Prendre une photo',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/analyse_camera',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ───── Carrousel météo ─────
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.13,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    buildFixedSizeCard(
                      title: ville.isNotEmpty
                          ? '$ville, ${DateTime.now().day} ${DateFormat.MMMM('fr_FR').format(DateTime.now())}'
                          : 'Chargement...',
                      subtitle: description.isNotEmpty ? description : '...',
                      iconWidget: icon.isNotEmpty
                          ? Image.network(
                              'https://openweathermap.org/img/wn/$icon@2x.png',
                              width: 40,
                              height: 40,
                            )
                          : const Icon(Icons.cloud),
                      value: temperature.isNotEmpty ? temperature : '...',
                    ),
                    buildFixedSizeCard(
                      title: 'Humidité',
                      subtitle: 'Niveau actuel',
                      iconWidget: const Icon(
                        Icons.water_drop,
                        color: Colors.blue,
                        size: 30,
                      ),
                      value: humidity.isNotEmpty ? humidity : '...',
                    ),
                    buildFixedSizeCard(
                      title: 'Vent',
                      subtitle: 'Vitesse',
                      iconWidget: const Icon(
                        Icons.air,
                        color: Colors.green,
                        size: 30,
                      ),
                      value: vitesseVentKMH != 0.0
                          ? '${vitesseVentKMH.toStringAsFixed(1)} km/h'
                          : '...',
                    ),
                    buildFixedSizeCard(
                      title: 'Lever du soleil',
                      subtitle: 'Heure locale',
                      iconWidget: const Icon(
                        Icons.wb_sunny_outlined,
                        color: Colors.orange,
                        size: 30,
                      ),
                      value: heureDuLever.isNotEmpty ? heureDuLever : '...',
                    ),
                    buildFixedSizeCard(
                      title: 'Coucher du soleil',
                      subtitle: 'Heure locale',
                      iconWidget: const Icon(
                        Icons.nightlight_outlined,
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                      value: heureDuCoucher.isNotEmpty ? heureDuCoucher : '...',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ───── Section : Maladies fréquentes ─────
              const Text(
                'Maladies fréquentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 260,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    MaladieCard(
                      imagePath: 'images/olivier.jfif',
                      nom: 'La cochenille',
                      description:
                          'Cet insecte apparaît au printemps lorsque le climat est chaud et humide. Il suce la sève de l\'olivier et forme des capsules noires sous les feuilles.',
                    ),
                    MaladieCard(
                      imagePath: 'images/pomme_de_terre.jpg',
                      nom: 'Mildiou',
                      description:
                          'Le mildiou de la pomme de terre, apparaît sous la forme d’une tache huileuse brun-marron, entourée d’un liseré vert clair. Un feutrage blanc peut apparaître sous la feuille par temps humide.',
                    ),
                    MaladieCard(
                      imagePath: 'images/fraise.jfif',
                      nom: 'botrytis',
                      description:
                          'Cette pourriture est due à un champignon : pourriture grise ou botrytis . Cette maladie se propage lorsqu\'il fait chaud et qu\'il y a trop d\'humidité dans l\’atmosphère.',
                    ),
                    MaladieCard(
                      imagePath: 'images/blé.jpg',
                      nom: ' l\'oïdium du blé',
                      description:
                          ' Taches blanches sur feuilles, fleurs ou fruits causées par un champignon.',
                    ),
                    MaladieCard(
                      imagePath: 'images/malade_tomate.jpg',
                      nom: ' l\'oïdium du tomate',
                      description:
                          'Aussi appelé pourriture blanche ou maladie du blanc, est une maladie cryptogamique, champignon qui cause des taches blanches sur les feuilles, fleurs et fruits.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ───── Section : Maladies détectées ─────
              const Text(
                'Maladies détectées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: maladiesData.isEmpty
                    ? const Center(child: Text('Aucune maladie détectée'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: maladiesData.length,
                        itemBuilder: (context, index) {
                          final maladie = maladiesData[index];

                          // Formatage de la date détectée
                          String dateFormatted = 'Date inconnue';
                          final ts = maladie['date_detectee'];
                          if (ts != null && ts is Timestamp) {
                            final d = ts.toDate();
                            dateFormatted =
                                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiseaseSimilarDetailsPage(
                                    nameFr: maladie['nom_francais'] ?? '',
                                    description: maladie['description'] ?? '',
                                    symptomes: maladie['symptomes'] ?? '',
                                    imageUrl: maladie['image_url'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    child:
                                        maladie['image_url'] != null &&
                                            maladie['image_url'].isNotEmpty
                                        ? Image.network(
                                            maladie['image_url'],
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      height: 100,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      ),
                                                    ),
                                          )
                                        : Container(
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          maladie['nom_francais'] ??
                                              'Nom inconnu',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Détectée le : $dateFormatted',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 30),

              // ───── Sections diverses ─────
              ConseilsDuJour(),
              const SizedBox(height: 40),
              buildAboutUs(),
              const SizedBox(height: 40),
              buildContactUs(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFixedSizeCard({
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required String value,
  }) {
    final double largeurCarte = MediaQuery.of(context).size.width * 0.8;
    return Container(
      width: largeurCarte,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAboutUs() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Row(
                  children: [
                    Icon(Icons.eco, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'SmartFarm',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Notre mission est d\'aider les agriculteurs à réussir grâce à des conseils intelligents.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'images/aboutus.jpg',
                  fit: BoxFit.cover,
                  height: 140,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContactUs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Contactez-nous',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          contactRow(Icons.email, 'contact@smartfarm.com.tn'),
          const SizedBox(height: 12),
          contactRow(Icons.phone, '+216 20 340 241'),
          const SizedBox(height: 12),
          contactRow(Icons.web, 'www.smartfarm.com.tn'),
        ],
      ),
    );
  }

  Widget contactRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────── Widget carte maladie ────────────────
class MaladieCard extends StatelessWidget {
  final String imagePath;
  final String nom;
  final String description;

  const MaladieCard({
    super.key,
    required this.imagePath,
    required this.nom,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              imagePath,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
