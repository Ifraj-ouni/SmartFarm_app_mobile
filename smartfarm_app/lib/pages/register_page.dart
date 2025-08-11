import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //TextEditingController ykhalina on accéde l texte
  //_nomController private
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  //final _culturesController = TextEditingController();

  final AuthService _authService = AuthService();

  //===== ajout pour afficher / cacher mot de passe =====
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }
  //======================================================

  //fonction tekhdem ken ki yenzel l'utilisateur aala s'inscrire
  void _register() async {
    //nekhou les valeurs eli ktebhom l'utilisateur
    final nom = _nomController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    //final cultures = _culturesController.text.trim();

    if (nom.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage("Veuillez remplir tous les champs.");
      return;
    }

    // vérifie si le mot de passe et confirmé ou confirmPassword
    if (password != confirmPassword) {
      _showMessage("Les mots de passe ne correspondent pas.");
      return;
    }

    if (!email.contains('@') || (!email.contains('.'))) {
      _showMessage("Vérifier votre email");
      return;
    }

    final error = await _authService.registerUser(
      nom: nom,
      email: email,
      role: 'client',
      password: password, 
    );

    if (error == null) {
      _showMessage(
        "Email de confirmation envoyé. Vérifiez votre boîte mail...",
      );
      _waitForEmailVerification();
    } else {
      _showMessage(error);
    }
  }

  void _waitForEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;

    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified == true) { //user != null && user.emailVerified
        _showMessage("Email vérifié. Bienvenue !");
        Navigator.pushReplacementNamed(context, '/accueil');
        return false;
      }

      return true;
    });
  }

  //fonction tkhalik taamale affiche l message
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/plante_background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 88, 71, 71).withOpacity(0.3),
          ),
          SingleChildScrollView(
            child: Container( //kenet Padding badaltha Container nafs l haja 
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Use',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'AgriScan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 89, 160, 92),
                    ),
                  ),
                  const SizedBox(height: 5),
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
                  const SizedBox(height: 30),

                  TextField(
                    controller: _nomController,
                    decoration: _buildInputDecoration('Nom complet'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration('Adresse e-mail'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, //=== utilisation ===
                    decoration: _buildInputDecoration(
                      'Mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword, //=== utilisation ===
                    decoration: _buildInputDecoration(
                      'Confirmez le mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 89, 160, 92),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Vous avez déjà un compte ?\n',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextSpan(
                            text: 'Se connecter',
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
        ],
      ),
    );
  }

  //nhot feha la décoration taa les input besh manabkach naawed feha fi kol input
  InputDecoration _buildInputDecoration(String label,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
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
      suffixIcon: suffixIcon, //=== ajout pour l’icône œil ===
    );
  }
}
