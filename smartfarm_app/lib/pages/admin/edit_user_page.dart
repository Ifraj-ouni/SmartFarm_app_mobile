import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
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
  final TextEditingController _phoneNumberOnlyController = TextEditingController();
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
      setState(() {
        // Optionnel: on peut filtrer la liste ici plus tard
      });
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
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

  String get _fullPhone => '+${selectedCountry.phoneCode}${_phoneNumberOnlyController.text.trim()}';

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editer utilisateur'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Utilisateur'), Tab(text: 'Champs')],
          ),
        ),
        body: TabBarView(
          children: [_buildUserForm(), _buildUserFields()],
        ),
      ),
    );
  }

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
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Veuillez entrer un nom' : null,
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
                            if (v == null || v.trim().isEmpty) return 'Veuillez entrer un email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email invalide';
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: _isEditing ? Colors.white : Colors.grey.shade200,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(selectedCountry.flagEmoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${selectedCountry.name} (+${selectedCountry.phoneCode})',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (_isEditing) const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('+${selectedCountry.phoneCode}', style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneNumberOnlyController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Numéro de téléphone',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Numéro requis';
                                  if (!RegExp(r'^[0-9]{6,12}\$').hasMatch(v.trim())) return 'Numéro invalide';
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
                          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: _isEditing ? (value) => setState(() => _selectedRole = value) : null,
                          validator: (v) => (v == null || v.isEmpty) ? 'Veuillez choisir un rôle' : null,
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
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

  Widget _buildUserFields() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par ville ou culture',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location_alt),
            label: const Text("Ajouter un champ"),
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
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fields')
                  .where('uid_user', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allFields = snapshot.data!.docs;
                if (allFields.isEmpty) return const Center(child: Text("Aucun champ trouvé"));

                return ListView.builder(
                  itemCount: allFields.length,
                  itemBuilder: (context, index) {
                    final doc = allFields[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final city = data['city'] ?? 'Ville inconnue';
                    final area = (data['area_m2'] as num?)?.toStringAsFixed(2) ?? '0';
                    final cultureId = data['selected_culture_id'] as String?;

                    return FutureBuilder<DocumentSnapshot>(
                      future: cultureId != null
                          ? FirebaseFirestore.instance.collection('cultures').doc(cultureId).get()
                          // ignore: null_argument_to_non_null_type
                          : Future.value(null),
                      builder: (context, snapshotCulture) {
                        Widget cultureDetails;

                        if (snapshotCulture.connectionState == ConnectionState.waiting) {
                          cultureDetails = const Center(child: CircularProgressIndicator());
                        } else if (!snapshotCulture.hasData || !snapshotCulture.data!.exists) {
                          cultureDetails = const Text('Aucune culture associée');
                        } else {
                          final cultureData = snapshotCulture.data!.data() as Map<String, dynamic>;

                          cultureDetails = Row(
                            children: [
                              if (cultureData['image_url'] != null)
                                Image.network(
                                  cultureData['image_url'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cultureData['nomCommun'] ?? 'Nom inconnu',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      cultureData['nomScientifique'] ?? '',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                    if (cultureData['chlorophylle'] != null)
                                      Text('Chlorophylle : ${cultureData['chlorophylle']}'),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: ExpansionTile(
                            leading: const Icon(Icons.agriculture),
                            title: Text("Champ n°${index + 1}"),
                            subtitle: Text(city),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Surface : $area m²"),
                                    const SizedBox(height: 8),
                                    const Text('Culture liée :', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    cultureDetails,
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.teal),
                                          tooltip: "Modifier",
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddEditFieldPage(
                                                  userId: widget.userId,
                                                  fieldId: doc.id,
                                                  isEditMode: true,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: "Supprimer",
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Confirmation"),
                                                content: const Text("Supprimer ce champ ?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text("Annuler"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text("Supprimer"),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await FirebaseFirestore.instance.collection('fields').doc(doc.id).delete();
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
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
}
