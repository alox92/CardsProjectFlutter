import 'package:flutter/material.dart';

/// Bouton avec effet de rebond lors des interactions
class AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  
  const AnimatedBounceButton({
    Key? key,
    required this.child, 
    required this.onTap
  }) : super(key: key);
  
  @override
  State<AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<AnimatedBounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: ElevatedButton(
            onPressed: widget.onTap,
            child: widget.child,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}