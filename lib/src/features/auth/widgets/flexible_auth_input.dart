import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';

class FlexibleAuthInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String value, bool isValid) onChanged;
  final bool enabled;
  final String? hintText;

  const FlexibleAuthInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<FlexibleAuthInput> createState() => _FlexibleAuthInputState();
}

class _FlexibleAuthInputState extends State<FlexibleAuthInput> {
  final AuthService _authService = AuthService();
  String _inputType = 'unknown';
  bool _isPhoneMode = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _updateInputType(widget.controller.text, notifyParent: false);
  }

  void _updateInputType(String value, {bool notifyParent = true}) {
    final inputType = _authService.getInputType(value);
    
    // Improved phone mode detection for Nigerian numbers
    final shouldBePhoneMode = inputType.startsWith('phone') || 
                              value.startsWith('0') || 
                              value.startsWith('+') ||
                              value.startsWith('234') ||
                              (value.length >= 1 && RegExp(r'^[789]').hasMatch(value));
    
    setState(() {
      _inputType = inputType;
      _isPhoneMode = shouldBePhoneMode;
      
      if (_isPhoneMode) {
        _isValid = _authService.isPhoneNumber(value);
      } else {
        _isValid = _authService.isPlateNumber(value);
      }
    });
    
    if (notifyParent) {
      widget.onChanged(value, _isValid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPhoneMode) {
      return _buildPhoneInput();
    } else {
      return _buildPlateInput();
    }
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: widget.hintText ?? '803 XXX XXXX',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.phone),
        suffixIcon: _getInputStatusIcon(),
        helperText: _getHelperText(),
        helperStyle: TextStyle(
          color: _getHelperTextColor(),
          fontSize: 12,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11), // Max length for Nigerian numbers (08066697348)
        _NigerianPhoneFormatter(),
      ],
      onChanged: (value) {
        _updateInputType(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        
        if (!_authService.isPhoneNumber(value)) {
          return 'Please enter a valid Nigerian phone number';
        }
        
        return null;
      },
    );
  }

  Widget _buildPlateInput() {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'ABC123DD or 0803XXXXXXX',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: _getInputIcon(),
        suffixIcon: _getInputStatusIcon(),
        helperText: _getHelperText(),
        helperStyle: TextStyle(
          color: _getHelperTextColor(),
          fontSize: 12,
        ),
      ),
      inputFormatters: [
        UpperCaseTextFormatter(),
        LengthLimitingTextInputFormatter(15), // Max length for phone or plate
      ],
      onChanged: (value) {
        widget.controller.text = value.toUpperCase();
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        _updateInputType(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number or plate number';
        }
        
        if (!_isValid) {
          if (_inputType.contains('phone')) {
            return 'Please enter a valid Nigerian phone number';
          } else if (_inputType.contains('plate')) {
            return 'Please enter a valid plate number (ABC123DD)';
          } else {
            return 'Please enter a valid phone number or plate number';
          }
        }
        
        return null;
      },
    );
  }

  Icon _getInputIcon() {
    switch (_inputType) {
      case 'phone':
        return const Icon(Icons.phone, color: AppColors.success);
      case 'plate':
        return const Icon(Icons.directions_car, color: AppColors.success);
      case 'phone_partial':
        return const Icon(Icons.phone, color: AppColors.warning);
      case 'plate_partial':
        return const Icon(Icons.directions_car, color: AppColors.warning);
      default:
        return const Icon(Icons.contact_phone, color: AppColors.textSecondary);
    }
  }

  Widget? _getInputStatusIcon() {
    if (widget.controller.text.isEmpty) return null;
    
    if (_isValid) {
      return const Icon(Icons.check_circle, color: AppColors.success);
    } else if (_inputType.contains('partial')) {
      return const Icon(Icons.more_horiz, color: AppColors.warning);
    } else {
      return const Icon(Icons.error, color: AppColors.error);
    }
  }

  String? _getHelperText() {
    switch (_inputType) {
      case 'phone':
        return 'Valid Nigerian phone number';
      case 'plate':
        return 'Valid Nigerian plate number';
      case 'phone_partial':
        return 'Continue typing your phone number...';
      case 'plate_partial':
        return 'Continue typing your plate number...';
      case 'unknown':
        if (widget.controller.text.isNotEmpty) {
          return 'Enter phone (0803XXXXXXX) or plate (ABC123DD)';
        }
        return 'Phone number or plate number';
      default:
        return null;
    }
  }

  Color _getHelperTextColor() {
    switch (_inputType) {
      case 'phone':
      case 'plate':
        return AppColors.success;
      case 'phone_partial':
      case 'plate_partial':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _NigerianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Format Nigerian phone numbers with spaces for better readability
    // 08066697348 -> 0806 669 7348
    if (text.length >= 4) {
      final buffer = StringBuffer();
      buffer.write(text.substring(0, 4));
      
      if (text.length > 4) {
        buffer.write(' ');
        buffer.write(text.substring(4, text.length > 7 ? 7 : text.length));
        
        if (text.length > 7) {
          buffer.write(' ');
          buffer.write(text.substring(7));
        }
      }
      
      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    }
    
    return newValue;
  }
}