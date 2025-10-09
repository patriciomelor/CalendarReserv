import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CustomCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onDelete,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.teal[100],
          child: Icon(icon, color: Colors.teal[800]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing:
            trailing ??
            (onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: onDelete,
                  )
                : null),
      ),
    );
  }
}
