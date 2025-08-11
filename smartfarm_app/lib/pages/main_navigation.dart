import 'package:flutter/material.dart';
import 'package:smartfarm_app/pages/DiseasePage.dart';
import 'package:smartfarm_app/pages/accueil_page.dart';
import 'package:smartfarm_app/pages/field_page.dart';
import 'package:smartfarm_app/pages/profile_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex; //par défaut 0 eli howa l home (accueil)

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex; //variable feha l index eli nezel aalih
  // liste feha les pages eli mawjoudin f navigationbottombar

  final List<Widget> _pages = [
    const AccueilPage(),
    const FieldPage(fieldId: ''),
    const DiseasePage(),
    const ProfilePage(),
  ];

  @override
  //fonction tekhdem awel ma tabda l création taa l widget
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    //fonction tekhdem awel ma tabda l création taa l widget
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCameraTap() {
    print("Caméra cliquée !");

    Navigator.pushReplacementNamed(context, '/analyse_camera');
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: isSelected ? Colors.green : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.green : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      // Bouton de caméra modifié pour ressembler à l'image
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: InkWell(
            onTap: _onCameraTap,
            borderRadius: BorderRadius.circular(35),
            child: const Icon(Icons.camera_alt, size: 25, color: Colors.white),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Partie gauche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildNavItem(icon: Icons.home, label: "Accueil", index: 0),
                    const SizedBox(width: 30),
                    _buildNavItem(
                      icon: Icons.local_florist,
                      label: "Cultures",
                      index: 1,
                    ),
                  ],
                ),
              ),

              // Partie droite
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: Icons.coronavirus,
                      label: "Maladies",
                      index: 2,
                    ),
                    const SizedBox(width: 30),
                    _buildNavItem(
                      icon: Icons.person,
                      label: "Profil",
                      index: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
