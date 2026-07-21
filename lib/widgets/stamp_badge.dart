import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tampon nordique affiché sur les défis validés.
class StampBadge extends StatelessWidget {
  final double size;

  const StampBadge({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 2.5),
        color: AppColors.success.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          '❄️',
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}
