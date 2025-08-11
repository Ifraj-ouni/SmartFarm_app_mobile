import 'dart:io';
import 'dart:convert'; // pour décoder les réponses JSON
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  String? _uploadedImageUrl;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromFirestore();
  }

  Future<void> _loadUserDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _uploadedImageUrl = data['avatar'];
          _userName = data['nom'] ?? 'Utilisateur';
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = 'dx1zihwal';
    const uploadPreset = 'fe3mrlpw';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);
      return data['secure_url'];
    } else {
      print('Erreur Cloudinary : ${response.statusCode}');
      return null;
    }
  }

  Future<void> _saveImageUrlToFirestore(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'avatar': imageUrl});
        print('URL enregistrée dans Firestore ✔');
      } catch (e) {
        print('Erreur Firestore : $e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _imageFile = file);

      final imageUrl = await _uploadToCloudinary(file);
      if (imageUrl != null) {
        setState(() => _uploadedImageUrl = imageUrl);
        await _saveImageUrlToFirestore(imageUrl);
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: _buildGradientIcon(Icons.photo),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: _buildGradientIcon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientIcon(IconData iconData, {double size = 24}) {
    final gradient = const LinearGradient(
      colors: [
        Color(0xFF739C3E), // vert forêt 0xFF228B22
        Color(0xFF739C3E), // vert mousse 0xFF228B23
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(bounds);
      },
      child: Icon(
        iconData,
        color: Colors.white,
        size: size,
      ),
    );
  }

  Widget buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _buildGradientIcon(icon),
      title: Text(title),
      trailing: _buildGradientIcon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _uploadedImageUrl != null
        ? NetworkImage(_uploadedImageUrl!)
        : _imageFile != null
            ? FileImage(_imageFile!) as ImageProvider
            : const AssetImage('images/default_avatar.jpg');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 60, backgroundImage: imageProvider),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: _buildGradientIcon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _userName ?? 'Utilisateur',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                buildProfileOption(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                buildProfileOption(
                  icon: Icons.edit,
                  title: 'Éditer le profil',
                  onTap: () => Navigator.pushNamed(context, '/editprofile'),
                ),
                buildProfileOption(
                  icon: Icons.handshake,
                  title: 'Nos partenaires',
                  onTap: () => Navigator.pushNamed(context, '/partenaires'),
                ),
                buildProfileOption(
                  icon: Icons.reviews,
                  title: 'Donnez votre avis',
                  onTap: () => Navigator.pushNamed(context, '/feedback'),
                ),
                buildProfileOption(
                  icon: Icons.contact_mail,
                  title: 'Contact & réseaux sociaux',
                  onTap: () => Navigator.pushNamed(context, '/contact'),
                ),
                buildProfileOption(
                  icon: Icons.help_center,
                  title: "Centre d'aide",
                  onTap: () => Navigator.pushNamed(context, '/help'),
                ),
                buildProfileOption(
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
