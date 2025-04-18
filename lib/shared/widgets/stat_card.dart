import 'package:flutter/material.dart';
import 'dart:ui';

/// Widget de carte de statistiques avec arrière-plan flou et mise en avant des données
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final double fontSize;
  final IconData? icon;
  
  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.fontSize = 16.0,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(45),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (icon != null) Icon(icon, color: color, size: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize + 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(blurRadius: 8, color: color, offset: Offset(0, 0)),
                  ],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  color: color.withAlpha(180),
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}