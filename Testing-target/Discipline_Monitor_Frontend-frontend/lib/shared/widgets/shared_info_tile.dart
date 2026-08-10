import 'package:flutter/material.dart';

class SharedInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const SharedInfoTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class SharedInfoCard extends StatelessWidget {
  final List<SharedInfoTile> tiles;

  const SharedInfoCard({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: tiles));
  }
}
