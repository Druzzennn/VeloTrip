import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chute de neige immersive, en fond d'écran. Purement décoratif.
class Snowfall extends StatefulWidget {
  /// Nombre de flocons (répartis sur 3 plans de profondeur).
  final int flakeCount;

  /// Multiplicateur de visibilité : 1 = normal, >1 = tempête.
  final double intensity;

  const Snowfall({
    super.key,
    this.flakeCount = 95,
    this.intensity = 1.45,
  });

  @override
  State<Snowfall> createState() => _SnowfallState();
}

class _SnowfallState extends State<Snowfall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Flake> _flakes;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _flakes = List.generate(
      widget.flakeCount,
      (_) => _Flake.random(_rng, widget.intensity),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.intensity;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Brume givrée — ciel polaire chargé.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white.withValues(alpha: 0.28 * i),
                  AppColors.white.withValues(alpha: 0.12 * i),
                  AppColors.white.withValues(alpha: 0.03 * i),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.15, 0.35, 0.6],
              ),
            ),
          ),
          // Voile latéral — impression de tempête.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.white.withValues(alpha: 0.06 * i),
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.white.withValues(alpha: 0.06 * i),
                ],
                stops: const [0.0, 0.15, 0.85, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SnowPainter(_flakes, _controller.value, i),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _FlakeDepth { far, mid, near }

class _Flake {
  final double x;
  final double startY;
  final double radius;
  final double speed;
  final double drift;
  final double windBias;
  final double opacity;
  final _FlakeDepth depth;
  final double phase;

  _Flake({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.windBias,
    required this.opacity,
    required this.depth,
    required this.phase,
  });

  factory _Flake.random(Random r, double intensity) {
    final roll = r.nextDouble();
    // Plus de flocons proches = effet tempête plus marqué.
    final depth = roll < 0.38
        ? _FlakeDepth.far
        : roll < 0.72
            ? _FlakeDepth.mid
            : _FlakeDepth.near;
    final scale = intensity.clamp(0.5, 2.5);

    return switch (depth) {
      _FlakeDepth.far => _Flake(
          x: r.nextDouble(),
          startY: r.nextDouble(),
          radius: (0.9 + r.nextDouble() * 1.6) * scale,
          speed: 0.5 + r.nextDouble() * 0.55,
          drift: (r.nextDouble() - 0.5) * 0.07,
          windBias: (r.nextDouble() - 0.5) * 0.015,
          opacity: (0.28 + r.nextDouble() * 0.32) * intensity,
          depth: depth,
          phase: r.nextDouble() * 2 * pi,
        ),
      _FlakeDepth.mid => _Flake(
          x: r.nextDouble(),
          startY: r.nextDouble(),
          radius: (1.8 + r.nextDouble() * 3.2) * scale,
          speed: 0.75 + r.nextDouble() * 0.95,
          drift: (r.nextDouble() - 0.5) * 0.13,
          windBias: (r.nextDouble() - 0.5) * 0.025,
          opacity: (0.45 + r.nextDouble() * 0.45) * intensity,
          depth: depth,
          phase: r.nextDouble() * 2 * pi,
        ),
      _FlakeDepth.near => _Flake(
          x: r.nextDouble(),
          startY: r.nextDouble(),
          radius: (3.5 + r.nextDouble() * 4.5) * scale,
          speed: 1.1 + r.nextDouble() * 1.1,
          drift: (r.nextDouble() - 0.5) * 0.18,
          windBias: (r.nextDouble() - 0.5) * 0.04,
          opacity: (0.6 + r.nextDouble() * 0.38) * intensity.clamp(0.5, 2.0),
          depth: depth,
          phase: r.nextDouble() * 2 * pi,
        ),
    };
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double t;
  final double intensity;
  _SnowPainter(this.flakes, this.t, this.intensity);

  double _windGust(double phase) =>
      1.0 + 0.9 * sin(t * 5 * pi + phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white;

    for (final f in flakes) {
      final progress = (f.startY + t * f.speed) % 1.0;
      final gust = _windGust(f.phase);
      final sway = sin((t + f.startY) * 2.5 * pi + f.phase) * f.drift * gust;
      var dx = f.x + sway + t * f.windBias * gust;
      dx = dx - dx.floor();

      final offset = Offset(dx * size.width, progress * size.height);
      final alpha = f.opacity.clamp(0.0, 1.0);
      paint.color = AppColors.white.withValues(alpha: alpha);

      switch (f.depth) {
        case _FlakeDepth.near:
          paint.color = AppColors.white.withValues(alpha: alpha * 0.35);
          canvas.drawCircle(offset, f.radius * 2.8, paint);
          paint.color = AppColors.white.withValues(alpha: alpha * 0.55);
          canvas.drawCircle(offset, f.radius * 1.5, paint);
          paint.color = AppColors.white.withValues(alpha: alpha);
          canvas.drawCircle(offset, f.radius, paint);
        case _FlakeDepth.mid:
          paint.color = AppColors.white.withValues(alpha: alpha * 0.2);
          canvas.drawCircle(offset, f.radius * 1.8, paint);
          paint.color = AppColors.white.withValues(alpha: alpha);
          canvas.drawCircle(offset, f.radius, paint);
        case _FlakeDepth.far:
          canvas.drawCircle(offset, f.radius, paint);
      }
    }

    // Couche de poussière de neige — micro-flocons très rapides.
    final dustCount = (18 * intensity).round();
    for (var i = 0; i < dustCount; i++) {
      final seed = i * 1.618;
      final dx = ((seed * 0.37 + t * 1.8) % 1.0) * size.width;
      final dy = ((seed * 0.53 + t * 2.4) % 1.0) * size.height;
      paint.color = AppColors.white.withValues(alpha: 0.18 * intensity);
      canvas.drawCircle(Offset(dx, dy), 0.8 + (seed % 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter old) =>
      old.t != t || old.intensity != intensity;
}
