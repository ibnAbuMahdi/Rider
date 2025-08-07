import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/bank_account_provider.dart';
import '../../../core/models/bank_account.dart';
import '../widgets/bank_selection_bottom_sheet.dart';

class AddBankAccountScreen extends ConsumerStatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  ConsumerState<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends ConsumerState<AddBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bvnController = TextEditingController();

  String? _selectedBankCode;
  String _selectedAccountType = 'savings';
  bool _isLoading = false;
  bool _isValidating = false;
  BankValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    // Load supported banks when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportedBanksProvider.notifier).loadSupportedBanks();
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bvnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankValidationState = ref.watch(bankValidationProvider);
    final validator = ref.watch(bankFormValidationProvider);

    // Listen to validation results
    ref.listen<AsyncValue<BankValidationResult?>>(bankValidationProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            setState(() {
              _validationResult = result;
              _isValidating = false;
            });

            if (result.valid && result.accountName != null) {
              _accountNameController.text = result.accountName!;
            } else if (!result.valid) {
              _showErrorDialog(result.message);
            }
          }
        },
        error: (error, _) {
          setState(() {
            _isValidating = false;
          });
          _showErrorDialog('Failed to validate bank details. Please try again.');
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBankSelectionField(),
              const SizedBox(height: 16),
              _buildAccountNumberField(),
              const SizedBox(height: 16),
              _buildValidationButton(),
              if (_validationResult?.valid == true) ...[
                const SizedBox(height: 16),
                _buildValidationResult(),
                const SizedBox(height: 16),
                _buildAccountNameField(validator),
                const SizedBox(height: 16),
                _buildAccountTypeField(),
                const SizedBox(height: 16),
                _buildBVNField(validator),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
              const SizedBox(height: 24),
              _buildHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Bank Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your bank account details to receive payments for your campaigns.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBankSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Bank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showBankSelectionBottomSheet,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _bankNameController.text.isEmpty 
                        ? 'Select your bank'
                        : _bankNameController.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: _bankNameController.text.isEmpty 
                          ? Colors.grey[500]
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        if (_selectedBankCode == null && _formKey.currentState?.validate() == false)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Please select a bank',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Enter your account number',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
          ),
          validator: ref.read(bankFormValidationProvider).validateAccountNumber,
          onChanged: (value) {
            // Clear validation when user changes account number
            if (_validationResult != null) {
              setState(() {
                _validationResult = null;
              });
              ref.read(bankValidationProvider.notifier).clearValidation();
            }
          },
        ),
      ],
    );
  }

  Widget _buildValidationButton() {
    final canValidate = _selectedBankCode != null && 
                       _accountNumberController.text.length >= 10;

    return ElevatedButton.icon(
      onPressed: canValidate && !_isValidating ? _validateBankDetails : null,
      icon: _isValidating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.search),
      label: Text(_isValidating ? 'Validating...' : 'Validate Account'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildValidationResult() {
    if (_validationResult?.valid != true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Validated!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                if (_validationResult?.accountName != null)
                  Text(
                    'Account Name: ${_validationResult!.accountName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountNameField(BankFormValidator validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Account holder name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator.validateAccountName,
        ),
      ],
    );
  }

  Widget _buildAccountTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAccountType,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccountType = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                DropdownMenuItem(value: 'current', child: Text('Current Account')),
                DropdownMenuItem(value: 'domiciliary', child: Text('Domiciliary Account')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBVNField(BankFormValidator validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BVN (Bank Verification Number)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Required for verification (11 digits)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bvnController,
          keyboardType: TextInputType.number,
          maxLength: 11,
          decoration: InputDecoration(
            hintText: 'Enter your 11-digit BVN',
            prefixIcon: const Icon(Icons.fingerprint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
          ),
          validator: validator.validateBVN,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Add Bank Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Adding Bank Account Help',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHelpItem('• Select your bank from the list'),
            _buildHelpItem('• Enter your complete account number'),
            _buildHelpItem('• Account name must match exactly with your bank records'),
            _buildHelpItem('• BVN is required for account verification'),
            _buildHelpItem('• Verification usually completes within 1-2 minutes'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.amber[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your bank details are encrypted and secure. We use bank-grade security to protect your information.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _showBankSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankSelectionBottomSheet(
        onBankSelected: (bank) {
          setState(() {
            _bankNameController.text = bank.name;
            _selectedBankCode = bank.code;
          });
          
          // Clear validation when bank changes
          if (_validationResult != null) {
            setState(() {
              _validationResult = null;
            });
            ref.read(bankValidationProvider.notifier).clearValidation();
          }
        },
      ),
    );
  }

  void _validateBankDetails() {
    if (_selectedBankCode == null || _accountNumberController.text.length < 10) {
      return;
    }

    setState(() {
      _isValidating = true;
    });

    ref.read(bankValidationProvider.notifier).validateBankDetails(
      bankCode: _selectedBankCode!,
      accountNumber: _accountNumberController.text.trim(),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && 
        _validationResult?.valid == true &&
        _selectedBankCode != null) {
      
      setState(() {
        _isLoading = true;
      });

      try {
        final bankService = ref.read(bankAccountServiceProvider);
        final newAccount = await bankService.createBankAccount(
          bankName: _bankNameController.text,
          bankCode: _selectedBankCode!,
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
          accountType: _selectedAccountType,
          bvn: _bvnController.text.trim(),
        );

        if (newAccount != null && mounted) {
          // Refresh bank accounts list
          ref.read(bankAccountsProvider.notifier).refreshAccounts();
          ref.read(bankAccountStatsProvider.notifier).refreshStats();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank account added successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog(ref.read(bankAccountServiceProvider).getErrorMessage(e));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}