import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

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
        // Logo icon
        SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            'assets/icons/tricycle.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
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