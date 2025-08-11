import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkTheme = false;
  String language = 'Français';
  bool notificationsEnabled = true;
  String notificationRate = 'Quotidien';
  String? avatarUrl;
  //rajaana l user l connécté
  final user = FirebaseAuth.instance.currentUser;
  //connexion maa l firestore
  final firestore = FirebaseFirestore.instance;

  bool isLoading = true;

  //Ki tetsama la page, tet3ayet lel fonction _loadPreferences() bach tjib les données de Firestore
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Charger préférences depuis Firestore
  //Hedhi fonction asynchrone (b async/await), bech tjib les données ml base sans bloquer l'app.
  Future<void> _loadPreferences() async {
    if (user == null)
      return; //Si l’utilisateur mouch connecté, ma na3mlou chay, n'quittiw la fonction direct
    try {
      final doc = await firestore
          .collection('users')
          .doc(user!.uid)
          .get(); //! yaani sur eli l user moch null
      if (doc.exists) {
        //Vérifie si le document mawjoud
        final data = doc
            .data()!; //Jibna les données ta3 l’utilisateur en format Map (clé: valeur).
        setState(() {
          //On met à jour les variables du widget (state) b données ml Firestore :
          isDarkTheme = data['isDarkTheme'] ?? false;
          avatarUrl = data['avatar']; // récupère l'url avatar
          language = data['language'] ?? 'Français';
          notificationsEnabled = data['notificationsEnabled'] ?? true;
          notificationRate = data['notificationRate'] ?? 'Quotidien';
        });
      }
    } catch (e) {
      debugPrint(
        "Erreur chargement prefs : $e",
      ); //Si fama problème (ex: pas de connexion, Firestore ma7abch yjib),
    }
    setState(() {
      isLoading = false; //Tawa el chargement mta3 les préférences est terminé
    });
  }

  // Sauvegarder préférences dans Firestore
  //Fonction async li bech tsajjel (sauvegarde) les préférences utilisateur fi Firestore sans bloquer l’app.
  Future<void> _savePreferences() async {
    if (user == null) return;
    try {
      await firestore.collection('users').doc(user!.uid).set(
        {
          'isDarkTheme': isDarkTheme,
          'language': language,
          'notificationsEnabled': notificationsEnabled,
          'notificationRate': notificationRate,
        },
        SetOptions(merge: true),
      ); //ça veut dire on met à jour seulement ces champs sans effacer les autres données déjà présentes dans le document.
    } catch (e) {
      debugPrint("Erreur sauvegarde prefs : $e");
    }
  }

  Future<void> _changePassword() async {
    final controller =
        TextEditingController(); //bech ykoun mawjoud 3and input texte, bach njibou mot de passe jdida.
    final formKey =
        GlobalKey<
          FormState
        >(); //houa clé li taaml contrôle w validation 3al formulaire.

    //N'affichiw fenêtre popup (dialogue) li manajmouch nsakkrouha b klikke barra (barrierDismissible: false),
    //w le résultat (success ou pas) yetraja3 fi success.
    final success = await showDialog<bool>(
      context: context, //contexte actuel de l’interface pour afficher la popup.
      barrierDismissible:
          false, //interdit à l’utilisateur de fermer la popup en cliquant en dehors.
      builder: (ctx) => AlertDialog(
        //Construction de la fenêtre popup qui va s’afficher (alert).
        title: const Text('Changer mot de passe'),
        //Le contenu du popup est un formulaire relié à la clé formKey pour validation.
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller, //controller : pour récupérer la saisie.
            obscureText: true, //obscureText: true → l’input ykoun maské (***).
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe', //étiquette du champ.
            ),
            validator: (val) {
              // fonction qui vérifie la validité (au moins 6 caractères).
              if (val == null || val.length < 6) {
                return 'Le mot de passe doit faire au moins 6 caractères';
              }
              return null;
            },
          ),
        ),
        actions: [
          //Annuler : ferme la popup et retourne false.
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          //Valide le formulaire (mot de passe ok).
          TextButton(
            onPressed: () async {
              //.validate() yappelle toutes les fonctions validator: li fama f les TextFormField.
              if (formKey.currentState!.validate()) {
                //formKey	Clé ta3 formulaire
                //currentState	état formulaire en ce moment
                //validate()	ychouf les champs si les valeurs s7i7a selon les règles (validator)
                //!	nta met2akid li currentState moch null
                try {
                  await user!.updatePassword(
                    controller.text,
                  ); //besh tbadel l mdp fel authentification firebase b texte eli fel controller
                  //Navigator.pop	tsakkir el popup / dialog
                  //ctx	contexte local mta3 el popup
                  //true	traja3 valeur true lel appel principal (yani réussite)
                  Navigator.pop(ctx, true);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe changé avec succès')),
      );
    }
  }

  //Cette fonction async, t7el popup ta3 choix de fréquence
  Future<void> _chooseNotificationRate() async {
    final rates = [
      'En temps réel',
      'Quotidien',
      'Hebdomadaire',
    ]; //Ta3ref une liste mta3 options li bech t5alli user y5tar mnha.
    final result = await showDialog<String>(
      //Taffichi un popup (dialogue) li ycontieni des boutons radio (RadioListTile).
      context: context,
      builder: (_) => SimpleDialog(
        //houwa le widget du popup (design plus simple que AlertDialog).
        title: const Text('Fréquence des notifications'),
        children:
            rates //Tnaffichi kol élément mn la liste rates f forma de RadioListTile :
                .map(
                  (r) => RadioListTile(
                    value: r,
                    groupValue: notificationRate,
                    title: Text(r),
                    onChanged: (val) =>
                        Navigator.pop(context, val), //temchi maa l radio button
                  ),
                )
                .toList(),
      ),
    );
    if (result != null) {
      //Tchouf si l’utilisateur a choisi une fréquence dans le popup.
      setState(
        () => notificationRate = result,
      ); //3tina valeur jdida, w 3ayyetna l setState() pour tet7addeth el écran.
      await _savePreferences(); //Ystanna l’exécution mta3 fonction _savePreferences()
    }
  }

  Future<void> _confirmDeleteAccount() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer le compte'),
      content: const Text("Cette action est irréversible. Continuer ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // Étape 1 : Supprimer les champs liés à l'utilisateur
      final fieldsSnapshot = await firestore
          .collection('fields')
          .where('uid_user', isEqualTo: user!.uid)
          .get();

      for (var doc in fieldsSnapshot.docs) {
        await firestore.collection('fields').doc(doc.id).delete();
      }

      // Étape 2 : Supprimer les données de l'utilisateur dans "users"
      await firestore.collection('users').doc(user!.uid).delete();

      // Étape 3 : Supprimer l'utilisateur dans Firebase Auth
      await user!.delete();

      // Étape 4 : Rediriger vers la page de connexion (ou accueil)
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}

  Future<void> _syncData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Synchronisation en cours...")),
    );
    await Future.delayed(const Duration(seconds: 2)); //nestanew 2 secondes
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Synchronisation terminée.")));
  }

  @override
  Widget build(BuildContext context) {
    //isLoading : boolean li y9oulna ken fama chargement.
    //CircularProgressIndicator() : spinner (daoura ta3 loading).
    //Scaffold : structure el page.
    //Center : ykhal spinner fi wast el écran.
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramétres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          //quand on clique, on ferme la page courante et on revient à la page précédente.
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(// une liste scrollable (verticalement).
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('👤 Utilisateur'),
          _simpleCard([
            ListTile(
              leading: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl!))
                  : const CircleAvatar(child: Icon(Icons.person)),//si on a une url valide, on affiche l’image de l’avatar sinon on met une icône par défaut
              title: Text(user?.email ?? 'Utilisateur anonyme'),//affiche l’email de l’utilisateur, ou "Utilisateur anonyme" si on n’a pas d’email.
              subtitle: const Text("Compte connecté"),
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('🎨 Personnalisation'),
          _simpleCard([
            SwitchListTile(
              title: const Text('Mode sombre'),
              value: isDarkTheme,
              onChanged: (val) async {
                setState(() => isDarkTheme = val);
                await _savePreferences();//fonction besh tbadel fel base
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              trailing: DropdownButton<String>(
                value: language,
                underline: const SizedBox.shrink(),
                items: ['Français', 'Anglais', 'Arabe']
                    .map(
                      (lang) =>
                          DropdownMenuItem(value: lang, child: Text(lang)),
                    )
                    .toList(),
                onChanged: (val) async {
                  setState(() => language = val!);
                  await _savePreferences();
                },
              ),
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('🔔 Notifications'),
          _simpleCard([
            SwitchListTile(
              title: const Text('Activer les notifications'),
              value: notificationsEnabled,
              onChanged: (val) async {
                setState(() => notificationsEnabled = val);
                await _savePreferences();
              },
              secondary: const Icon(Icons.notifications),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Fréquence'),
              subtitle: Text(notificationRate),
              onTap: _chooseNotificationRate,
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('🧰 Compte & sécurité'),
          _simpleCard([
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Changer mot de passe'),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Synchroniser les données'),
              onTap: _syncData,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _confirmDeleteAccount,
            ),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('ℹ À propos'),
          _simpleCard([
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('À propos de l’application'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'SmartFarm',
                applicationVersion: '1.0.0',
                children: const [
                  Text('Application agricole intelligente basée sur l’IA.'),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'SmartFarm © 2025',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _simpleCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(children: children),
    );
  }
}
