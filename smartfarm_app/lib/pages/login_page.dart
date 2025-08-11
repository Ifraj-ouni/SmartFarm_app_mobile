import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 pour récupérer le rôle
import 'package:smartfarm_app/pages/admin/admin_page.dart';
import 'register_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  // ======= AJOUT pour la visibilité du mot de passe =======
  bool _obscureText = true; // true => mot de passe caché
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText; // inverse l’état
    });
  }
  // ========================================================

  //fonction tkhalik taamale affiche l message
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ======= 🔐 function taa login w redirection selon le rôle =======
  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (!mounted) return;

      if (user != null && user.emailVerified) {
        // 🔍 on récupère les infos de l’utilisateur connecté depuis Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role =
            doc.data()?['role'] ?? 'client'; // par défaut client si pas défini

        // 🔁 redirection selon le rôle
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ), // vers la page admin
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/accueil',
          ); // vers la page normale
        }
      } else {
        _showMessage("Veuillez vérifier votre adresse e-mail.");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage("Erreur : ${e.message}");
    } finally {
      setState(() => isLoading = false);
    }
  }
  // ========================================================

  //fonction tekhdem ken ki yenzel aal boutton mot de passe oublié
  //tabaath lien de réinsialisation taa mot de passe aal email eli ketbou l utilisateur
  //fonction ne retourne rien et asynchrone
  Future<void> _resetPassword() async {
    final email = emailController.text
        .trim(); //emailController eli f textEditingController

    if (email.isEmpty) {
      _showMessage("Veuillez entrer votre adresse e-mail");
      return; //taamel stop lel function ken l email vide
    }

    setState(() => isLoading = true); //pour afficher un loader

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      //sendPasswordResetEmail() : méthode fournie par Firebase pour envoyer un email de réinitialisation.
      _showMessage("Un e-mail de réinitialisation a été envoyé à $email");
    } on FirebaseAuthException catch (e) {
      _showMessage("Erreur : ${e.message}");
      //FirebaseAuthException : classe d’erreur fournie par Firebase Auth.
    } finally {
      setState(
        () => isLoading = false,
      ); //setState méthode par défaut de StatefulWidget.
    }
  }

  @override
  void initState() {
    super.initState();

    // ======= Préchargement de l’image de fond =======
    // hedhi taamel precache bel post frame bch context ykoun available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage("images/plante_background.jpg"), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        //stack ki yabda aandek hajet besh thothom fouk baadhhom superposé kima beckground foukha form w lkol
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/plante_background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(
            color: const Color.fromARGB(255, 88, 71, 71).withOpacity(0.3),
          ),
          // Content
          SingleChildScrollView(
            //ywali fama scroll ki yfout taille de l'écran
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Use',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AgriScan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 89, 160, 92),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'easily',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'One account, for all the agri services\nfor your farm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 15),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText:
                          _obscureText, // ===== on utilise l’état _obscureText =====
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                        // ===== AJOUT de l’icône œil =====
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed:
                              _togglePasswordVisibility, // appel de la fonction
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    //mdp oublié
                    InkWell(
                      onTap: isLoading ? null : _resetPassword,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 20),
                        alignment: Alignment.topRight,
                        child: const Text(
                          "Mot de passe oublié?",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Connexion button
                    ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 10),

                    // Redirection vers Register
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Vous n\'avez pas encore de compte ?\n',
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextSpan(
                              text: 'Créer un compte',
                              style: TextStyle(
                                color: Color.fromARGB(255, 89, 160, 92),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/*
Stack:
T7eb t7ot composants fawk baadhhom (superposés).
Background image w text fawka
Bouton t7etlo f coin mta page (overlay)

SingleChildScrollView
Formulaire, page ma t3awedch (statique) mais t7ebha scrollable.
Exemple :
Formulaire d’inscription
Écran paramètres

ListView
Liste d’éléments homogènes (articles, users, notifications).
Liste des cultures, messages, ou produits
T7ot ListView ki :
3andek liste dynamique (yji mel Firebase par exemple)
barka nafs el widget yet3awed bel ListView.builder
*/
