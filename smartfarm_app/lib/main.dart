import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartfarm_app/firebase_options.dart';
import 'package:smartfarm_app/pages/LiveCameraCapturePage.dart';
import 'package:smartfarm_app/pages/add_culture_page.dart';
import 'package:smartfarm_app/pages/chatbot_page.dart';
//import 'package:smartfarm_app/pages/field_page.dart';
import 'package:smartfarm_app/pages/contact_page.dart';
import 'package:smartfarm_app/pages/editprofile_page.dart';
//import 'package:smartfarm_app/pages/accueil_page.dart';
import 'package:smartfarm_app/pages/main_navigation.dart';
import 'package:smartfarm_app/pages/help_center_page.dart';
import 'package:smartfarm_app/pages/settings_page.dart';
import 'package:smartfarm_app/pages/feedback_page.dart';
import 'package:smartfarm_app/pages/partenaires_page.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';

void main() async {
  //quand tu veux faire des appels asynchrones avant runApp() (comme l'initialisation Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //Elle charge les données de traduction des dates pour la locale fr_FR (français – France), depuis le package intl.
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

// Rendu Stateful
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plante IA',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        //sinon ken besh naamel kif haka lele field '/field': (context) => fieldPage(), moch besh yaffichi l bottomNavigationBar
        //yaani ki besh yenzel aala l prendre une photo besh yemchi lel field w ki yji mechi lel field yemchi lel page MainNavigation w bel index 1 eli howa page Field;
        '/field': (context) => const MainNavigation(
          initialIndex: 1,
        ), //'/field': (context) => FieldPage(),
        '/help': (context) => const HelpCenterPage(),
        '/settings': (context) => const SettingsPage(),
        '/contact': (context) => const ContactPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/editprofile': (context) => const EditProfilePage(),
        '/partenaires': (context) => PartenairesPage(),
        '/analyse_camera': (context) => const LiveCameraCapturePage(),
        '/chatbot': (context) => ChatbotPage(),
        '/add_culture': (context) => AddCulturePage(fieldId: 'fieldId',),
        '/accueil': (context) =>
            const MainNavigation(), //fel mainnavigation nhot feha l contenu mtaa page d'accueil
      },
    );
  }
}
