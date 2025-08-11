import 'package:flutter/material.dart';

// Importe tes pages UsersPage et CulturesPage et diseasePage ici
import 'users_page.dart';     // Remplace par le chemin réel
import 'cultures_page.dart';  // Remplace par le chemin réel
import 'disease_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Ici 3 onglets : Utilisateurs, maladies et Cultures
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Gestion"),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.person), text: "Utilisateurs"),
            Tab(icon: Icon(Icons.local_florist), text: "Cultures"),
            Tab(icon:Icon(Icons.coronavirus),text:"Maladies"),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          UsersPage(),
          CulturesPage(),
          DiseasePage(),
        ],
      ),
    ),
  );
}

}
