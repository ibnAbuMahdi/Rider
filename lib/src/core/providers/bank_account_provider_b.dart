import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/bank_account.dart';
import '../services/bank_account_service.dart';

// Bank account service provider
final bankAccountServiceProvider = Provider<BankAccountService>((ref) {
  return BankAccountService();
});

// Supported banks provider
final supportedBanksProvider = StateNotifierProvider<SupportedBanksNotifier, AsyncValue<List<SupportedBank>>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return SupportedBanksNotifier(bankService);
});

// Bank accounts provider
final bankAccountsProvider = StateNotifierProvider<BankAccountsNotifier, AsyncValue<List<BankAccount>>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return BankAccountsNotifier(bankService);
});

// Primary bank account provider
final primaryBankAccountProvider = StateNotifierProvider<PrimaryBankAccountNotifier, AsyncValue<BankAccount?>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return PrimaryBankAccountNotifier(bankService);
});

// Bank account stats provider
final bankAccountStatsProvider = StateNotifierProvider<BankAccountStatsNotifier, AsyncValue<BankAccountStats?>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return BankAccountStatsNotifier(bankService);
});

// Bank validation provider (for form validation)
final bankValidationProvider = StateNotifierProvider<BankValidationNotifier, AsyncValue<BankValidationResult?>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return BankValidationNotifier(bankService);
});

// Verification logs provider
final verificationLogsProvider = StateNotifierProvider<VerificationLogsNotifier, AsyncValue<List<BankVerificationLog>>>((ref) {
  final bankService = ref.watch(bankAccountServiceProvider);
  return VerificationLogsNotifier(bankService);
});

class SupportedBanksNotifier extends StateNotifier<AsyncValue<List<SupportedBank>>> {
  final BankAccountService _bankService;

  SupportedBanksNotifier(this._bankService) : super(const AsyncValue.loading()) {
    loadSupportedBanks();
  }

  Future<void> loadSupportedBanks({bool? instantOnly, String? search}) async {
    try {
      state = const AsyncValue.loading();
      final banks = await _bankService.getSupportedBanks(
        instantOnly: instantOnly,
        search: search,
      );
      state = AsyncValue.data(banks);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Load supported banks error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshBanks() async {
    await loadSupportedBanks();
  }

  List<SupportedBank> searchBanks(String query) {
    final currentBanks = state.valueOrNull ?? [];
    return _bankService.searchBanks(currentBanks, query);
  }

  SupportedBank? findBankByCode(String code) {
    final currentBanks = state.valueOrNull ?? [];
    return _bankService.findBankByCode(currentBanks, code);
  }
}

class BankAccountsNotifier extends StateNotifier<AsyncValue<List<BankAccount>>> {
  final BankAccountService _bankService;

  BankAccountsNotifier(this._bankService) : super(const AsyncValue.loading()) {
    loadBankAccounts();
  }

  Future<void> loadBankAccounts() async {
    try {
      state = const AsyncValue.loading();
      final accounts = await _bankService.getBankAccounts();
      state = AsyncValue.data(accounts);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Load bank accounts error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshAccounts() async {
    await loadBankAccounts();
  }

  Future<BankAccount?> createAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required String accountType,
    String? bvn,
    String? sortCode,
  }) async {
    try {
      final newAccount = await _bankService.createBankAccount(
        bankName: bankName,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
        accountType: accountType,
        bvn: bvn,
        sortCode: sortCode,
      );

      if (newAccount != null) {
        // Refresh the list to include the new account
        await refreshAccounts();
      }

      return newAccount;
    } catch (error) {
      if (kDebugMode) {
        print('Create account error: $error');
      }
      rethrow;
    }
  }

  Future<BankAccount?> updateAccount(
    int accountId, {
    String? bankName,
    String? accountName,
    String? accountType,
    String? bvn,
    String? sortCode,
    bool? isActive,
  }) async {
    try {
      final updatedAccount = await _bankService.updateBankAccount(
        accountId,
        bankName: bankName,
        accountName: accountName,
        accountType: accountType,
        bvn: bvn,
        sortCode: sortCode,
        isActive: isActive,
      );

      if (updatedAccount != null) {
        // Update the account in the current state
        final currentAccounts = state.valueOrNull ?? [];
        final updatedAccounts = currentAccounts.map((account) {
          return account.id == accountId ? updatedAccount : account;
        }).toList();
        
        state = AsyncValue.data(updatedAccounts);
      }

      return updatedAccount;
    } catch (error) {
      if (kDebugMode) {
        print('Update account error: $error');
      }
      rethrow;
    }
  }

  Future<bool> deleteAccount(int accountId) async {
    try {
      final success = await _bankService.deleteBankAccount(accountId);

      if (success) {
        // Remove the account from the current state
        final currentAccounts = state.valueOrNull ?? [];
        final updatedAccounts = currentAccounts.where((account) => account.id != accountId).toList();
        state = AsyncValue.data(updatedAccounts);
      }

      return success;
    } catch (error) {
      if (kDebugMode) {
        print('Delete account error: $error');
      }
      rethrow;
    }
  }

  Future<bool> setPrimaryAccount(int accountId) async {
    try {
      final success = await _bankService.setPrimaryAccount(accountId);

      if (success) {
        // Update the accounts to reflect new primary status
        final currentAccounts = state.valueOrNull ?? [];
        final updatedAccounts = currentAccounts.map((account) {
          return BankAccount(
            id: account.id,
            bankName: account.bankName,
            bankCode: account.bankCode,
            accountNumber: account.accountNumber,
            maskedAccountNumber: account.maskedAccountNumber,
            accountName: account.accountName,
            accountType: account.accountType,
            bvn: account.bvn,
            sortCode: account.sortCode,
            status: account.status,
            verificationStatus: account.verificationStatus,
            isPrimary: account.id == accountId,
            isActive: account.isActive,
            verifiedAt: account.verifiedAt,
            verificationAttempts: account.verificationAttempts,
            lastVerificationAttempt: account.lastVerificationAttempt,
            verificationNotes: account.verificationNotes,
            totalPaymentsReceived: account.totalPaymentsReceived,
            paymentCount: account.paymentCount,
            lastPaymentDate: account.lastPaymentDate,
            displayName: account.displayName,
            verificationProgress: account.verificationProgress,
            canReceivePayments: account.canReceivePayments,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
          );
        }).toList();
        
        state = AsyncValue.data(updatedAccounts);
      }

      return success;
    } catch (error) {
      if (kDebugMode) {
        print('Set primary account error: $error');
      }
      rethrow;
    }
  }

  Future<bool> resendVerification(int accountId) async {
    try {
      final success = await _bankService.resendVerification(accountId);

      if (success) {
        // Refresh accounts to get updated verification status
        await refreshAccounts();
      }

      return success;
    } catch (error) {
      if (kDebugMode) {
        print('Resend verification error: $error');
      }
      rethrow;
    }
  }

  // Helper getters
  List<BankAccount> get verifiedAccounts {
    final accounts = state.valueOrNull ?? [];
    return accounts.where((account) => account.isVerified).toList();
  }

  List<BankAccount> get pendingAccounts {
    final accounts = state.valueOrNull ?? [];
    return accounts.where((account) => account.isPending).toList();
  }

  BankAccount? get primaryAccount {
    final accounts = state.valueOrNull ?? [];
    try {
      return accounts.firstWhere((account) => account.isPrimary);
    } catch (e) {
      return null;
    }
  }

  bool get hasAccounts {
    final accounts = state.valueOrNull ?? [];
    return accounts.isNotEmpty;
  }

  bool get hasPrimaryAccount {
    return primaryAccount != null;
  }
}

class PrimaryBankAccountNotifier extends StateNotifier<AsyncValue<BankAccount?>> {
  final BankAccountService _bankService;

  PrimaryBankAccountNotifier(this._bankService) : super(const AsyncValue.loading()) {
    loadPrimaryAccount();
  }

  Future<void> loadPrimaryAccount() async {
    try {
      state = const AsyncValue.loading();
      final primaryAccount = await _bankService.getPrimaryAccount();
      state = AsyncValue.data(primaryAccount);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Load primary account error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshPrimaryAccount() async {
    await loadPrimaryAccount();
  }
}

class BankAccountStatsNotifier extends StateNotifier<AsyncValue<BankAccountStats?>> {
  final BankAccountService _bankService;

  BankAccountStatsNotifier(this._bankService) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      state = const AsyncValue.loading();
      final stats = await _bankService.getBankAccountStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Load bank account stats error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }
}

class BankValidationNotifier extends StateNotifier<AsyncValue<BankValidationResult?>> {
  final BankAccountService _bankService;

  BankValidationNotifier(this._bankService) : super(const AsyncValue.data(null));

  Future<void> validateBankDetails({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      state = const AsyncValue.loading();
      final result = await _bankService.validateBankDetails(
        bankCode: bankCode,
        accountNumber: accountNumber,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Bank validation error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearValidation() {
    state = const AsyncValue.data(null);
  }
}

class VerificationLogsNotifier extends StateNotifier<AsyncValue<List<BankVerificationLog>>> {
  final BankAccountService _bankService;

  VerificationLogsNotifier(this._bankService) : super(const AsyncValue.loading()) {
    loadVerificationLogs();
  }

  Future<void> loadVerificationLogs() async {
    try {
      state = const AsyncValue.loading();
      final logs = await _bankService.getVerificationLogs();
      state = AsyncValue.data(logs);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Load verification logs error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshLogs() async {
    await loadVerificationLogs();
  }
}

// Helper provider for form validations
final bankFormValidationProvider = Provider<BankFormValidator>((ref) {
  return BankFormValidator();
});

class BankFormValidator {
  String? validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account number is required';
    }
    
    // Remove any non-numeric characters
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.length < 10) {
      return 'Account number must be at least 10 digits';
    }
    
    if (cleaned.length > 20) {
      return 'Account number cannot exceed 20 digits';
    }
    
    return null;
  }

  String? validateAccountName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Account name must be at least 2 characters';
    }
    
    // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[A-Za-z0-9\s\-'\.]+$").hasMatch(value)) {
      return 'Account name contains invalid characters';
    }
    
    return null;
  }

  String? validateBVN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // BVN is optional
    }
    
    // Remove any non-numeric characters
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.length != 11) {
      return 'BVN must be exactly 11 digits';
    }
    
    return null;
  }

  String? validateBankCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bank selection is required';
    }
    
    return null;
  }
}