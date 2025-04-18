import 'package:flutter/material.dart';

class SyncInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const SyncInfoRow({required this.label, required this.value, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
