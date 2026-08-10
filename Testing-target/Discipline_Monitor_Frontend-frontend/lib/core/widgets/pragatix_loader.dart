import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PragatiXLoader extends StatefulWidget {
  final String message;
  final bool fullScreen;
  final double width;
  final double height;

  const PragatiXLoader({
    super.key,
    this.message = 'Loading',
    this.fullScreen = true,
    this.width = 120,
    this.height = 120,
  });

  @override
  State<PragatiXLoader> createState() => _PragatiXLoaderState();
}

class _PragatiXLoaderState extends State<PragatiXLoader> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    // Rotation (2.0s infinite linear)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget loaderContent = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -12,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo + Ring + Glow
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  Container(
                    width: widget.width * 0.8,
                    height: widget.height * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),

                  // Rotating Gradient Ring
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 4,
                              color: Colors.transparent,
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const SweepGradient(
                                colors: [Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFF97316)],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(rect);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(width: 4, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Logo (Static)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/images/sg_logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Text
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B), 
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.fullScreen) {
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark Blur Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: const Color(0xAA0F172A), // rgba(15, 23, 42, 0.65)
                ),
              ),
            ),
            loaderContent,
          ],
        ),
      );
    }

    return loaderContent;
  }
}
