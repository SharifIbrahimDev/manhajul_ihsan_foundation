// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryOrange = Colors.orange;
  static const Color accentYellow = Colors.yellow;
  // Add rainbow accents as gradients if needed
  static LinearGradient rainbowGradient = LinearGradient(
    colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.orange],
  );
}