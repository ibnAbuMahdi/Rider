import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/loading_button.dart';
import '../../shared/widgets/stika_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;
  bool _isPlateValid = true; // Optional field, so starts as valid
  bool _includePlateNumber = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _plateController.dispose();
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
        title: Text(
          'Create Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Logo
                const StikaLogo(size: 80),
                const SizedBox(height: 24),
                
                // Welcome text
                Text(
                  'Join Stika Rider',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Start earning money while you ride',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Phone number input (required)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Phone Number',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'NG',
                          enabled: !authState.isLoading,
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
                              // Use our custom validation instead of IntlPhoneField's built-in validation
                              _isPhoneValid = _authService.isValidNigerianPhone(phone.completeNumber);
                            });
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
                        ),
                        
                        const SizedBox(height: 8),
                        Text(
                          'Required for account verification',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Plate number input (optional)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Plate Number',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Optional',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          'Add your tricycle plate number if you have one',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Toggle for plate number
                        CheckboxListTile(
                          value: _includePlateNumber,
                          onChanged: authState.isLoading ? null : (value) {
                            setState(() {
                              _includePlateNumber = value ?? false;
                              if (!_includePlateNumber) {
                                _plateController.clear();
                                _isPlateValid = true;
                              }
                            });
                          },
                          title: const Text('I have a tricycle plate number'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        // Plate input field (only show if checked)
                        if (_includePlateNumber) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _plateController,
                            enabled: !authState.isLoading,
                            decoration: InputDecoration(
                              hintText: 'ABC123DD',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.directions_car),
                              suffixIcon: _isPlateValid && _plateController.text.isNotEmpty
                                  ? const Icon(Icons.check_circle, color: AppColors.success)
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              final formatted = value.toUpperCase();
                              if (formatted != value) {
                                _plateController.text = formatted;
                                _plateController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: formatted.length),
                                );
                              }
                              
                              setState(() {
                                _isPlateValid = _authService.isPlateNumber(formatted);
                              });
                            },
                            validator: (value) {
                              if (_includePlateNumber && (value == null || value.isEmpty)) {
                                return 'Please enter your plate number';
                              }
                              if (_includePlateNumber && !_authService.isPlateNumber(value!)) {
                                return 'Please enter a valid plate number (ABC123DD)';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 8),
                          Text(
                            'Format: ABC123DD (3 letters, 3 numbers, 2 letters)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                
                // Create account button
                LoadingButton(
                  onPressed: _canCreateAccount() ? _createAccount : null,
                  isLoading: authState.isLoading,
                  child: const Text('CREATE ACCOUNT'),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: authState.isLoading ? null : () {
                        context.pop(); // Go back to welcome/login screen
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Log in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Terms and conditions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy',
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
    );
  }

  bool _canCreateAccount() {
    return _isPhoneValid && 
           (!_includePlateNumber || _isPlateValid);
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();
    
    try {
      final plateNumber = _includePlateNumber && _plateController.text.isNotEmpty 
          ? _plateController.text.toUpperCase() 
          : null;
      
      final success = await ref.read(authProvider.notifier).signup(
        phone: _completePhoneNumber,
        plate: plateNumber,
      );
      
      if (success && mounted) {
        // Navigate to OTP verification
        context.push('/auth/verify-otp', extra: _completePhoneNumber);
      }
    } catch (e) {
      // Error is handled by the provider
    }
  }
}