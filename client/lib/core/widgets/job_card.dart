import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.province,
    this.onTap,
  });

  final String title;
  final String companyName;
  final String province;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$companyName · $province'),
        onTap: onTap,
      ),
    );
  }
}
