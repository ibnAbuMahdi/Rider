import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_button.dart';

class PlateNumberActivationDialog extends ConsumerStatefulWidget {
  final VoidCallback? onActivationSuccess;

  const PlateNumberActivationDialog({
    super.key,
    this.onActivationSuccess,
  });

  @override
  ConsumerState<PlateNumberActivationDialog> createState() =>
      _PlateNumberActivationDialogState();
}

class _PlateNumberActivationDialogState
    extends ConsumerState<PlateNumberActivationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Section
            Container(
              padding: const EdgeInsets.all(24),
              child: const Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Activate Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Section (FIXED)
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your tricycle plate number to activate your account:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Plate number input
                      TextFormField(
                        controller: _plateController,
                        decoration: InputDecoration(
                          labelText: 'Plate Number',
                          hintText: 'e.g. ABC123DD',
                          prefixIcon: const Icon(Icons.confirmation_number),
                          errorText: _errorMessage,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Z0-9]')),
                          LengthLimitingTextInputFormatter(8),
                          _PlateNumberFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your plate number';
                          }
                          if (value.length != 8) {
                            return 'Plate number must be 8 characters';
                          }
                          if (!RegExp(r'^[A-Z]{3}[0-9]{3}[A-Z]{2}$')
                              .hasMatch(value)) {
                            return 'Invalid format. Use format: ABC123DD';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      LoadingButton(
                        text: 'Activate',
                        isLoading: _isLoading,
                        onPressed: _activateAccount,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plateNumber = _plateController.text.trim().toUpperCase();
      final success =
          await ref.read(authProvider.notifier).activateRider(plateNumber);

      if (mounted) {
        if (success) {
          // Show success dialog
          await _showSuccessDialog();

          // Call success callback
          widget.onActivationSuccess?.call();

          // Close activation dialog
          Navigator.of(context).pop();
        } else {
          // Show error from auth provider
          final authState = ref.read(authProvider);
          setState(() {
            _errorMessage =
                authState.error ?? 'Activation failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'An error occurred. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your account has been activated successfully!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can now join campaigns and start earning!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    return newValue.copyWith(text: text);
  }
}
