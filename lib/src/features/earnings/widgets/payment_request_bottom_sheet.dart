import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/earnings_provider.dart';
import '../../../shared/widgets/loading_button.dart';

class PaymentRequestBottomSheet extends ConsumerStatefulWidget {
  final double availableAmount;

  const PaymentRequestBottomSheet({
    super.key,
    required this.availableAmount,
  });

  @override
  ConsumerState<PaymentRequestBottomSheet> createState() =>
      _PaymentRequestBottomSheetState();
}

class _PaymentRequestBottomSheetState
    extends ConsumerState<PaymentRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.availableAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Request Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Available Balance: ₦${widget.availableAmount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Request',
                prefixText: '₦ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid amount';
                }
                
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                
                if (amount > widget.availableAmount) {
                  return 'Amount cannot exceed available balance';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 24),
            LoadingButton(
              onPressed: _isLoading ? null : _handlePaymentRequest,
              isLoading: _isLoading,
              text: 'Request Payment',
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      await ref.read(earningsProvider.notifier).requestPayment(
        amount: amount,
        paymentMethod: 'bank_transfer',
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
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