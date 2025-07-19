import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/stika_logo.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 48,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and welcome text
                  const StikaLogo(size: 120),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Welcome to Stika Rider',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Earn money while you ride',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                
                // Phone number input
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wetin be your phone number?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'NG',
                          decoration: InputDecoration(
                            hintText: '803 XXX XXXX',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          onChanged: (phone) {
                            setState(() {
                              _completePhoneNumber = phone.completeNumber;
                              _isPhoneValid = phone.isValidNumber();
                            });
                          },
                          validator: (phone) {
                            if (phone == null || !phone.isValidNumber()) {
                              return 'Please enter a valid Nigerian phone number';
                            }
                            return null;
                          },
                          disableLengthCheck: false,
                          flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        
                        // Helper text
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll send you a verification code',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Error message
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
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
                
                // Send OTP button
                LoadingButton(
                  onPressed: _isPhoneValid ? _sendOTP : null,
                  isLoading: authState.isLoading,
                  child: const Text('SEND CODE'),
                ),
                
                  const SizedBox(height: 40),
                  
                  // Terms and conditions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();
    
    try {
      await ref.read(authProvider.notifier).sendOTP(_completePhoneNumber);
      
      if (mounted) {
        context.push('/auth/verify-otp', extra: _completePhoneNumber);
      }
    } catch (e) {
      // Error is handled by the provider
    }
  }
}