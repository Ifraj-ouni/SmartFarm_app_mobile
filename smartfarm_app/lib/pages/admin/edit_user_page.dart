import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:smartfarm_app/pages/admin/add_edit_field_page.dart';

class EditUserPage extends StatefulWidget {
  final String userId;

  const EditUserPage({super.key, required this.userId});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberOnlyController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Country selectedCountry = Country.parse('TN');
  String? _selectedRole;
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> roles = ['client', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _deleteFieldWithMaladies(String fieldId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce champ et toutes les maladies associées ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final batch = FirebaseFirestore.instance.batch();

    // Supprimer le champ
    final fieldRef = FirebaseFirestore.instance
        .collection('fields')
        .doc(fieldId);
    batch.delete(fieldRef);

    // Supprimer toutes les maladies liées à ce champ
    final maladiesQuery = await FirebaseFirestore.instance
        .collection('maladies_users_champs')
        .where('id_field', isEqualTo: fieldId)
        .get();

    for (final doc in maladiesQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Champ et maladies associées supprimés')),
    );
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = doc.data();
    if (data != null) {
      _nomController.text = data['nom'] ?? '';
      _emailController.text = data['email'] ?? '';
      _selectedRole = data['role'] ?? 'client';
      final countryCode = data['country'] as String?;
      try {
        selectedCountry = Country.parse((countryCode ?? 'TN').toUpperCase());
      } catch (_) {
        selectedCountry = Country.parse('TN');
      }
      final storedPhone = (data['phone'] as String?) ?? '';
      final dial = '+${selectedCountry.phoneCode}';
      _phoneNumberOnlyController.text = storedPhone.startsWith(dial)
          ? storedPhone.substring(dial.length)
          : storedPhone;
    }
    setState(() => _isLoading = false);
  }

  String get _fullPhone =>
      '+${selectedCountry.phoneCode}${_phoneNumberOnlyController.text.trim()}';

  Future<List<Map<String, dynamic>>> _preloadMaladies() async {
    final query = await FirebaseFirestore.instance
        .collection('maladies_users_champs')
        .where('uid_user', isEqualTo: widget.userId)
        .orderBy('date', descending: true)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (final doc in query.docs) {
      final data = doc.data();
      final idMaladie = data['id_maladie'];
      final notes = data['notes_utilisateur'] ?? '';
      final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final fieldId = data['id_field'];

      // Charger la maladie
      final maladieDoc = await FirebaseFirestore.instance
          .collection('maladies')
          .doc(idMaladie)
          .get();
      final maladieData = maladieDoc.exists
          ? maladieDoc.data() as Map<String, dynamic>
          : {};

      // Récupérer la ville si fieldId existe
      String? city;
      if (fieldId != null && fieldId != "none") {
        final fieldDoc = await FirebaseFirestore.instance
            .collection('fields')
            .doc(fieldId)
            .get();
        if (fieldDoc.exists) city = fieldDoc.data()?['city'];
      }

      // Symptômes
      final symptomes =
          (data['symptomes_observes'] as List<dynamic>?)
                  ?.join(', ')
                  .trim()
                  .isNotEmpty ==
              true
          ? (data['symptomes_observes'] as List<dynamic>).join(', ')
          : (maladieData['symptomes'] ?? 'N/A');

      // Image
      final imageUrl =
          (data['image_url'] != null && data['image_url'].toString().isNotEmpty)
          ? data['image_url']
          : (maladieData['image_url'] ?? '');

      result.add({
        'nom': maladieData['nom_francais'] ?? 'Nom inconnu',
        'notes': notes,
        'date': date,
        'symptomes': symptomes,
        'imageUrl': imageUrl,
        'city': city,
      });
    }

    return result;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'nom': _nomController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _fullPhone,
            'country': selectedCountry.countryCode,
            'role': _selectedRole,
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur mis à jour avec succès !')),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneNumberOnlyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 👉 maintenant 3 onglets
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editer utilisateur'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Utilisateur'),
              Tab(text: 'Champs'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserForm(),
            _buildUserFields(),
            _buildUserMaladies(), // 👉 nouvel onglet
          ],
        ),
      ),
    );
  }

  /// Onglet 1 : Formulaire utilisateur
  Widget _buildUserForm() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit),
                      label: Text(_isEditing ? 'Annuler' : 'Modifier'),
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nomController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Veuillez entrer un nom'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Veuillez entrer un email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                              return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _isEditing
                              ? () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: true,
                                    onSelect: (Country country) {
                                      setState(() => selectedCountry = country);
                                    },
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? Colors.white
                                  : Colors.grey.shade200,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  selectedCountry.flagEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${selectedCountry.name} (+${selectedCountry.phoneCode})',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (_isEditing)
                                  const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${selectedCountry.phoneCode}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneNumberOnlyController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Numéro de téléphone',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Numéro requis';
                                  if (!RegExp(
                                    r'^[0-9]{6,12}\$',
                                  ).hasMatch(v.trim()))
                                    return 'Numéro invalide';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Rôle',
                            border: OutlineInputBorder(),
                          ),
                          items: roles
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: _isEditing
                              ? (value) => setState(() => _selectedRole = value)
                              : null,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Veuillez choisir un rôle'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Enregistrer'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  /// Onglet 2 : Champs
  Widget _buildUserFields() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par ville ou culture',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton Ajouter un champ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text(
                "Ajouter un champ",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditFieldPage(
                      userId: widget.userId,
                      isEditMode: false,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Liste des champs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fields')
                  .where('uid_user', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final allFields = snapshot.data!.docs;
                if (allFields.isEmpty)
                  return const Center(child: Text("Aucun champ trouvé"));

                return ListView.builder(
                  itemCount: allFields.length,
                  itemBuilder: (context, index) {
                    final doc = allFields[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final city = data['city'] ?? 'Ville inconnue';
                    final area =
                        (data['area_m2'] as num?)?.toStringAsFixed(2) ?? '0';
                    final cultureId = data['selected_culture_id'] as String?;

                    return FutureBuilder<DocumentSnapshot>(
                      future: cultureId != null
                          ? FirebaseFirestore.instance
                                .collection('cultures')
                                .doc(cultureId)
                                .get()
                          // ignore: null_argument_to_non_null_type
                          : Future.value(null),
                      builder: (context, snapshotCulture) {
                        Widget cultureDetails;

                        if (snapshotCulture.connectionState ==
                            ConnectionState.waiting) {
                          cultureDetails = const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (!snapshotCulture.hasData ||
                            !snapshotCulture.data!.exists) {
                          cultureDetails = const Text(
                            'Aucune culture associée',
                          );
                        } else {
                          final cultureData =
                              snapshotCulture.data!.data()
                                  as Map<String, dynamic>;
                          cultureDetails = Row(
                            children: [
                              if (cultureData['image_url'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    cultureData['image_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cultureData['nomCommun'] ?? 'Nom inconnu',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      cultureData['nomScientifique'] ?? '',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    if (cultureData['chlorophylle'] != null)
                                      Text(
                                        'Chlorophylle : ${cultureData['chlorophylle']}',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.agriculture,
                              color: Colors.green,
                            ),
                            title: Text(city),
                            childrenPadding: const EdgeInsets.all(12),
                            children: [
                              Text(
                                "Surface : $area m²",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              cultureDetails,
                              const SizedBox(height: 12),
                              // 🔹 Modifier / Supprimer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: "Modifier",
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddEditFieldPage(
                                                userId: widget.userId,
                                                isEditMode: true,
                                                fieldId: doc.id,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: "Supprimer",
                                    onPressed: () => _deleteFieldWithMaladies(
                                      doc.id,
                                    ), // 🔹 Appel direct
                                  ),
                                ],
                              ),
                              _buildFieldMaladies(doc.id),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


Widget _buildFieldMaladies(String fieldId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('maladies_users_champs')
        .where("id_field", isEqualTo: fieldId)
        .orderBy('date', descending: true)
        .snapshots(),
    builder: (context, snapshotMaladies) {
      if (snapshotMaladies.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshotMaladies.hasData || snapshotMaladies.data!.docs.isEmpty) {
        return const Text("Aucune maladie associée");
      }

      final maladiesDocs = snapshotMaladies.data!.docs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: maladiesDocs.map((maladieDoc) {
          final maladieData = maladieDoc.data() as Map<String, dynamic>;
          final maladieId = maladieData['id_maladie'] as String?;
          final Timestamp? ts = maladieData['date'];
          final DateTime? date = ts?.toDate();
          final List symptomesObserves =
              (maladieData['symptomes_observes'] as List?) ?? [];

          if (maladieId == null) return const SizedBox();

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('maladies')
                .doc(maladieId)
                .get(),
            builder: (context, snapshotDetail) {
              if (snapshotDetail.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                );
              }
              if (!snapshotDetail.hasData || !snapshotDetail.data!.exists) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  child: ListTile(
                    title: Text("Maladie inconnue ($maladieId)"),
                  ),
                );
              }

              final detail =
                  snapshotDetail.data!.data() as Map<String, dynamic>;
              final nomMaladie = detail['nom_francais'] ?? 'Sans nom';
              final imageMaladie = detail['image_url'] ?? '';
              final symptomesParDefaut = detail['symptomes'] ?? '';

              // Texte à afficher : Symptômes observés ou symptomes de la collection
              final symptomesTexte = symptomesObserves.isNotEmpty
                  ? "Symptômes observés : ${symptomesObserves.join(', ')}"
                  : "Symptômes : $symptomesParDefaut";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                child: ListTile(
                  leading: imageMaladie.isNotEmpty
                      ? Image.network(imageMaladie,
                          width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(nomMaladie),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date != null) Text("Date : ${date.toLocal()}"),
                      if (symptomesTexte.isNotEmpty) Text(symptomesTexte),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      );
    },
  );
}


  /// Onglet 3 : Maladies
  Widget _buildUserMaladies() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _preloadMaladies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucune maladie signalée"));
        }
        final maladies = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: maladies.length,
          itemBuilder: (context, index) {
            final data = maladies[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: data['imageUrl'].isNotEmpty
                      ? Image.network(
                          data['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.bug_report, size: 50),
                ),
                title: Text(
                  data['nom'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['notes'].isNotEmpty)
                        Text('Notes : ${data['notes']}'),
                      const SizedBox(height: 4),
                      Text('Symptômes : ${data['symptomes']}'),
                      const SizedBox(height: 4),
                      Text(
                        '📅 ${DateFormat('dd MMMM yyyy – HH:mm', 'fr_FR').format(data['date'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      if (data['city'] != null)
                        Text(
                          '📍 Ville : ${data['city']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
                // onTap supprimé
              ),
            );
          },
        );
      },
    );
  }
}
