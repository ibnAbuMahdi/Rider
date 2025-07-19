import 'package:flutter/material.dart';

class AppSecurity {
  static bool _isSecured = false;
  
  static void secure() {
    _isSecured = true;
  }
  
  static void unsecure() {
    _isSecured = false;
  }
  
  static bool get isSecured => _isSecured;
  
  // Mock methods to replace secure_application functionality
  static Widget secureApp({
    required Widget child,
    bool? secured,
    String? debugLabel,
  }) {
    return child; // Return child directly since we're not implementing actual security
  }
  
  static void lock() {
    _isSecured = true;
  }
  
  static void unlock() {
    _isSecured = false;
  }
}