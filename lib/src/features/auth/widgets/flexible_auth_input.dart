import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _updateInputType(widget.controller.text, notifyParent: false);
  }

  void _updateInputType(String value, {bool notifyParent = true}) {
    final inputType = _authService.getInputType(value);
    final shouldBePhoneMode = inputType.startsWith('phone') || 
                              (value.startsWith('0') || value.startsWith('+'));
    
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
    return IntlPhoneField(
      controller: widget.controller,
      initialCountryCode: 'NG',
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText ?? '803 XXX XXXX',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.phone),
        suffixIcon: _getInputStatusIcon(),
      ),
      onChanged: (phone) {
        _phoneNumber = phone.completeNumber;
        _updateInputType(_phoneNumber);
      },
      validator: (phone) {
        if (phone == null || phone.completeNumber.isEmpty) {
          return 'Please enter a phone number';
        }
        // Use our custom validation instead of IntlPhoneField's built-in validation
        if (!_authService.isValidNigerianPhone(phone.completeNumber)) {
          return 'Please enter a valid Nigerian phone number';
        }
        return null;
      },
      disableLengthCheck: false,
      flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 16),
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