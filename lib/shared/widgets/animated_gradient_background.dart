import 'package:flutter/material.dart';

/// Widget pour créer un arrière-plan dégradé animé
class AnimatedGradientBackground extends StatefulWidget {
  final List<Color>? colors;
  final Duration duration;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  
  const AnimatedGradientBackground({
    Key? key,
    this.colors,
    this.duration = const Duration(seconds: 5),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Color> _defaultColors = [
    Colors.blue,
    Colors.purple,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  List<Color> get _colors => widget.colors ?? _defaultColors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final colors = <Color>[];
        
        // Crée un dégradé animé en alternant entre les couleurs
        for (int i = 0; i < _colors.length; i++) {
          final nextIndex = (i + 1) % _colors.length;
          final color = Color.lerp(
            _colors[i],
            _colors[nextIndex],
            _controller.value,
          )!;
          colors.add(color);
        }
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}