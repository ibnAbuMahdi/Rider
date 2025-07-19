import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StikaLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const StikaLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon - for now using a placeholder
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bike,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'STIKA',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}