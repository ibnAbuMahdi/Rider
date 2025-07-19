import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart'; // Added import
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/stika_logo.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  
  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  // Updated to use AppConstants.otpLength (4 digits)
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String _otp = '';
  bool _canResend = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and focus nodes based on OTP length
    _controllers = List.generate(AppConstants.otpLength, (index) => TextEditingController());
    _focusNodes = List.generate(AppConstants.otpLength, (index) => FocusNode());
    
    // Start resend countdown
    _startResendCountdown();
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    _canResend = false;
    _resendCountdown = 60;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
          }
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              const StikaLogo(size: 80),
              const SizedBox(height: 32),
              
              // Title and subtitle
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'We sent a ${AppConstants.otpLength}-digit code to', // Dynamic text
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              Text(
                widget.phoneNumber,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),