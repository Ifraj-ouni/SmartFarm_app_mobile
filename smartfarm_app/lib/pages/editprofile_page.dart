// edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../services/edit_profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final EditProfileService _service = EditProfileService();

  @override
  void initState() {
    super.initState();
    _service.loadUserData(() => setState(() {})); // charger les données
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editer le profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Nom',
                        icon: Icons.person,
                        controller: _service.nameController,
                        editable: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          if (v.trim().length < 2) {
                            return 'Au moins 2 caractères';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Email',
                        icon: Icons.email,
                        controller: _service.emailController,
                        editable: false,
                        validator: (v) {
                          final reg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (v == null || v.trim().isEmpty) {
                            return 'Email requis';
                          }
                          if (!reg.hasMatch(v.trim())) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildCountryPicker(),
                      const SizedBox(height: 10),
                      _buildPhoneField(),
                      _buildTextField(
                        label: 'Bio',
                        icon: Icons.info,
                        controller: _service.bioController,
                        editable: true,
                        maxLines: 3,
                        validator: (v) {
                          if (v != null && v.length > 150) {
                            return 'Maximum 150 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => _service.saveProfile(_formKey, context),
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool editable,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        enabled: editable,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: editable ? Colors.white : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
    return InkWell(
      onTap: () {
        showCountryPicker(
          context: context,
          showPhoneCode: true,
          onSelect: (Country c) => setState(() {
            _service.selectedCountry = c;
          }),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(_service.selectedCountry.flagEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_service.selectedCountry.name} (+${_service.selectedCountry.phoneCode})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${_service.selectedCountry.phoneCode}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _service.phoneNumberOnlyController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Numéro de téléphone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Numéro requis';
                }
                if (!RegExp(r'^[0-9]{6,12}$').hasMatch(v.trim())) {
                  return 'Numéro invalide';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
