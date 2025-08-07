import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/fleet_provider.dart';
import '../../../core/models/fleet_owner.dart';
import '../../../core/models/fleet_status.dart';
import '../widgets/fleet_info_card.dart';

class FleetJoinScreen extends ConsumerStatefulWidget {
  const FleetJoinScreen({super.key});

  @override
  ConsumerState<FleetJoinScreen> createState() => _FleetJoinScreenState();
}

class _FleetJoinScreenState extends ConsumerState<FleetJoinScreen> {
  final _fleetCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FleetOwner? _foundFleet;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _fleetCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(fleetLookupProvider);
    final joinState = ref.watch(fleetJoinProvider);

    // Listen to lookup results
    ref.listen<AsyncValue<FleetLookupResult?>>(fleetLookupProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            if (result.success && result.fleet != null) {
              setState(() {
                _foundFleet = result.fleet;
                _showConfirmation = true;
              });
            } else {
              _showErrorDialog(result.message);
            }
          }
        },
        error: (error, _) {
          _showErrorDialog('Failed to lookup fleet. Please try again.');
        },
      );
    });

    // Listen to join results
    ref.listen<AsyncValue<FleetJoinResult?>>(fleetJoinProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            if (result.success) {
              _showSuccessDialog(result.message);
            } else {
              _showErrorDialog(result.message);
            }
          }
        },
        error: (error, _) {
          _showErrorDialog('Failed to join fleet. Please try again.');
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Fleet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFleetCodeInput(),
                const SizedBox(height: 20),
                _buildLookupButton(),
                if (_showConfirmation && _foundFleet != null) ...[
                  const SizedBox(height: 24),
                  FleetInfoCard(fleet: _foundFleet!),
                  const SizedBox(height: 20),
                  _buildConfirmationButtons(),
                ],
                if (!_showConfirmation) ...[
                  const SizedBox(height: 32),
                  _buildInfoSection(),
                ],
              ],
            ),
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
          'Join a Fleet',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your fleet code to join a fleet and start earning with team support.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFleetCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fleet Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fleetCodeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit fleet code (e.g., ABC123)',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
          ),
          maxLength: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Fleet code is required';
            }
            if (value.trim().length != 6) {
              return 'Fleet code must be 6 characters';
            }
            return null;
          },
          onChanged: (value) {
            // Clear previous lookup/confirmation when user starts typing again
            if (_showConfirmation) {
              setState(() {
                _showConfirmation = false;
                _foundFleet = null;
              });
              ref.read(fleetLookupProvider.notifier).clearLookup();
            }
          },
        ),
      ],
    );
  }

  Widget _buildLookupButton() {
    final lookupState = ref.watch(fleetLookupProvider);
    final isLoading = lookupState.isLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : _lookupFleet,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Lookup Fleet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildConfirmationButtons() {
    final joinState = ref.watch(fleetJoinProvider);
    final isJoining = joinState.isLoading;

    return Column(
      children: [
        ElevatedButton(
          onPressed: isJoining ? null : _joinFleet,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: isJoining
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Join This Fleet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isJoining ? null : _cancelJoin,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Join a Fleet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem('1. Get a 6-digit fleet code from your fleet manager'),
            _buildInfoItem('2. Enter the code above and tap "Lookup Fleet"'),
            _buildInfoItem('3. Review the fleet information'),
            _buildInfoItem('4. Confirm to join and start earning together'),
            const SizedBox(height: 16),
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
                    Icons.warning_amber,
                    color: Colors.amber[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can only be in one fleet at a time. Joining a new fleet will remove you from your current fleet.',
                      style: TextStyle(
                        fontSize: 14,
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

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _lookupFleet() {
    if (_formKey.currentState!.validate()) {
      final fleetCode = _fleetCodeController.text.trim().toUpperCase();
      ref.read(fleetLookupProvider.notifier).lookupFleet(fleetCode);
    }
  }

  void _joinFleet() {
    if (_foundFleet != null) {
      final fleetCode = _fleetCodeController.text.trim().toUpperCase();
      ref.read(fleetJoinProvider.notifier).joinFleet(fleetCode, ref);
    }
  }

  void _cancelJoin() {
    setState(() {
      _showConfirmation = false;
      _foundFleet = null;
    });
    ref.read(fleetLookupProvider.notifier).clearLookup();
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}