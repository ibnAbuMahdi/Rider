import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6A1B9A); // Purple - main brand color
  static const Color primaryDark = Color(0xFF4A148C);
  static const Color primaryLight = Color(0xFF9C47D0);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFF93C5FD);
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Orange/Yellow for warnings
  static const Color accentLight = Color(0xFFFBBF24);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Very light gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  
  // Gray Colors
  static const Color gray = Color(0xFF6B7280); // Medium gray
  static const Color lightGray = Color(0xFF9CA3AF); // Light gray
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color info = Color(0xFF3B82F6); // Blue
  
  // Status Light Variants
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoLight = Color(0xFFDEF7FF);
  
  // Functional Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  
  // Input Colors
  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputFocused = primary;
  
  // Navigation Colors
  static const Color navigationBackground = Color(0xFFFFFFFF);
  static const Color navigationSelected = primary;
  static const Color navigationUnselected = textSecondary;
  
  // Earnings Colors (Nigerian Naira context)
  static const Color earnings = Color(0xFF059669); // Darker green for money
  static const Color earningsBackground = Color(0xFFECFDF5);
  static const Color pending = warning;
  static const Color pendingBackground = warningLight;
  
  // Campaign Status Colors
  static const Color campaignActive = success;
  static const Color campaignPaused = warning;
  static const Color campaignEnded = textSecondary;
  
  // Verification Colors
  static const Color verificationRequired = error;
  static const Color verificationPassed = success;
  static const Color verificationFailed = error;
  static const Color verificationPending = warning;
  
  // Map Colors
  static const Color mapPrimary = primary;
  static const Color mapSecondary = secondary;
  static const Color geofenceFill = Color(0x1A6A1B9A);
  static const Color geofenceBorder = primary;
  static const Color routeColor = secondary;
  
  // Button Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6A1B9A),
    Color(0xFF4A148C),
  ];
  
  static const List<Color> earningsGradient = [
    Color(0xFF059669),
    Color(0xFF047857),
  ];
  
  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFF3F4F6);
  static const Color shimmerHighlight = Color(0xFFE5E7EB);
  
  // Offline/Online Indicators
  static const Color online = success;
  static const Color offline = error;
  static const Color syncing = warning;
  
  // Nigerian Context Colors
  static const Color nairaGreen = Color(0xFF008751); // Nigerian flag green
  static const Color lagosBlue = Color(0xFF0066CC); // Lagos state blue
  
  // Dark variants (for future dark theme support)
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  
  // Utility methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
  
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}