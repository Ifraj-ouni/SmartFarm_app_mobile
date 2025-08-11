//l page ki mayabda aandek hata field
import 'package:flutter/material.dart';
import 'field_list.dart';
import 'history_page.dart';

class FieldPage extends StatefulWidget {
  const FieldPage({super.key, required String fieldId});

  @override
  State<FieldPage> createState() => _FieldPageState();
}

class _FieldPageState extends State<FieldPage> {
  int _currentIndex = 0;

  final Color selectedColor = const Color(0xFF228B22);
  final Color unselectedColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTab("Mes champs", Icons.agriculture, 0),
            const SizedBox(width: 50),
            _buildTab("Historique", Icons.history, 1),
          ],
        ),
      ),
      body: _currentIndex == 0 ? const FieldList() : const HistoryPage(),
    );
  }

  Widget _buildTab(String title, IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
