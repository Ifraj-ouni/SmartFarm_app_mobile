import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartfarm_app/pages/admin/edit_user_page.dart';
import 'package:smartfarm_app/pages/admin/add_user_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String searchQuery = '';

  void _editUser(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserPage(userId: userId)),
    );
  }

  void _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Tu veux vraiment supprimer cet utilisateur ?"),
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
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom ou email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase().trim());
              },
            ),
          ),

          // Bouton Ajouter un utilisateur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 24),
                label: const Text(
                  "Ajouter un utilisateur",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.tealAccent.withOpacity(0.5),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddUserPage(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = (data['nom'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return nom.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur trouvé"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final avatarUrl = data['avatar']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : const AssetImage('images/default_avatar.jpg')
                                  as ImageProvider,
                        ),
                        title: Text(data['nom'] ?? 'Sans nom'),
                        subtitle: Text(data['email'] ?? ''),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Rôle : ${data['role'] ?? 'client'}"),
                                Text("Téléphone : ${data['phone'] ?? 'N/A'}"),
                                Text("Pays : ${data['country'] ?? 'N/A'}"),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: "Modifier",
                                      onPressed: () => _editUser(doc.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: "Supprimer",
                                      onPressed: () => _deleteUser(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 🔽 Historique des maladies
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('maladies_users_champs')
                                .where('uid_user', isEqualTo: doc.id)
                                .orderBy('date', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("Erreur de chargement de l'historique"),
                                );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final maladies = snapshot.data!.docs;

                              if (maladies.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("Aucun historique de maladies"),
                                );
                              }

                              return Column(
                                children: maladies.map((maladieDoc) {
                                  final maladie = maladieDoc.data()
                                      as Map<String, dynamic>;
                                  final Timestamp? ts = maladie['date'];
                                  final DateTime? date = ts?.toDate();
                                  final symptomes =
                                      (maladie['symptomes_observes'] as List?) ??
                                          [];
                                  final String maladieId =
                                      maladie['id_maladie'] ?? '';

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('maladies')
                                        .doc(maladieId)
                                        .get(),
                                    builder: (context, maladieSnapshot) {
                                      if (maladieSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (!maladieSnapshot.hasData ||
                                          !maladieSnapshot.data!.exists) {
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          child: ListTile(
                                            title: Text(
                                                "Maladie inconnue ($maladieId)"),
                                          ),
                                        );
                                      }

                                      final maladieData =
                                          maladieSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final String nomMaladie =
                                          maladieData['nom_francais'] ??
                                              'Sans nom';
                                      final String imageMaladie =
                                          maladieData['image_url'] ?? '';

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        child: ListTile(
                                          leading: maladie['image_url'] != null
                                              ? Image.network(
                                                  maladie['image_url'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                )
                                              : (imageMaladie.isNotEmpty
                                                  ? Image.network(
                                                      imageMaladie,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const Icon(Icons
                                                      .image_not_supported)),
                                          title: Text(nomMaladie),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (date != null)
                                                Text(
                                                    "Date : ${date.toLocal()}"),
                                              Text(
                                                  "Notes : ${maladie['notes_utilisateur'] ?? ''}"),
                                              Text(
                                                  "Symptômes : ${symptomes.join(', ')}"),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
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
