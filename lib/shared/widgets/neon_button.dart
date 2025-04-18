import 'package:flutter/material.dart';
import 'dart:ui';

/// Widget personnalisé pour créer un bouton avec un effet néon
class NeonButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final double borderRadius;
  final double blurRadius;
  final double glowFactor;
  final EdgeInsetsGeometry padding;

  const NeonButton({
    Key? key,
    required this.onTap,
    required this.child,
    this.color = Colors.blue,
    this.borderRadius = 16.0,
    this.blurRadius = 16.0,
    this.glowFactor = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
  }) : super(key: key);

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowOpacity = (_glowAnimation.value * 0.4) * widget.glowFactor;
        final borderOpacity = (_glowAnimation.value * 0.7) * widget.glowFactor;
        
        return GestureDetector(
          onTap: () {
            // Effet pulse sur tap
            _controller.forward(from: 0.0).then((_) {
              widget.onTap();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha((glowOpacity * 255).toInt()),
                  blurRadius: widget.blurRadius * _glowAnimation.value,
                  spreadRadius: widget.blurRadius * 0.2 * _glowAnimation.value,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 4.0,
                  sigmaY: 4.0,
                ),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: widget.color.withAlpha((borderOpacity * 255).toInt()),
                      width: 1.5,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}