import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String _otp = '';

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
                'We sent a 6-digit code to',
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
              const SizedBox(height: 48),
              
              // OTP Input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPBox(index)),
              ),
              
              // Error message
              if (authState.error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Verify button
              LoadingButton(
                onPressed: _otp.length == 6 ? _verifyOTP : null,
                isLoading: authState.isLoading,
                child: const Text('VERIFY CODE'),
              ),
              
              const SizedBox(height: 24),
              
              // Resend code
              TextButton(
                onPressed: authState.isLoading ? null : _resendOTP,
                child: Text(
                  'Didn\'t receive code? Resend',
                  style: TextStyle(
                    color: authState.isLoading ? AppColors.textSecondary : AppColors.primary,
                  ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus ? AppColors.primary : AppColors.border,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) => _onOTPChanged(index, value),
      ),
    );
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, remove focus
        _focusNodes[index].unfocus();
      }
    } else {
      // Move to previous field if current is empty
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    
    // Build OTP string
    _otp = _controllers.map((controller) => controller.text).join();
    setState(() {});
  }

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) return;
    
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();
    
    final success = await ref.read(authProvider.notifier).verifyOTP(widget.phoneNumber, _otp);
    
    if (success && mounted) {
      // Check if rider has completed onboarding
      final rider = ref.read(authProvider).rider;
      if (rider?.hasCompletedOnboarding == true) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _resendOTP() async {
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();
    
    try {
      await ref.read(authProvider.notifier).sendOTP(widget.phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Error is handled by the provider
    }
  }
}