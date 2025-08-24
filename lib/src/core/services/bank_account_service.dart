import 'package:flutter/foundation.dart';

import '../models/bank_account.dart';
import 'api_service.dart';

class BankAccountService {
  final ApiService _apiService;

  BankAccountService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Get all supported banks
  Future<List<SupportedBank>> getSupportedBanks({
    bool? instantOnly,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      
      if (instantOnly == true) {
        queryParameters['instant_only'] = 'true';
      }
      
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _apiService.get(
        '/riders/banks/supported/',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final data = response.data as Map<String, dynamic>;
      
      // Check if this is a Monnify response format
      if (data['success'] == true && data['source'] == 'monnify' && data['banks'] != null) {
        final List<dynamic> banks = data['banks'];
        return banks
            .map((bank) => SupportedBank.fromMonnifyResponse(bank as Map<String, dynamic>))
            .toList();
      }
      
      // Handle standard format
      final List<dynamic> results = data['results'] ?? data['banks'] ?? [];
      
      return results
          .map((bank) => SupportedBank.fromJson(bank as Map<String, dynamic>))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('Get supported banks error: $e');
        print('Response data type: ${e.runtimeType}');
      }
      
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Get all bank accounts for the authenticated rider
  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final response = await _apiService.get('/riders/bank-accounts/');
      
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] ?? [];
      
      return results
          .map((account) => BankAccount.fromJson(account as Map<String, dynamic>))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('Get bank accounts error: $e');
      }
      
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Get a specific bank account by ID
  Future<BankAccount?> getBankAccount(int accountId) async {
    try {
      final response = await _apiService.get('/riders/bank-accounts/$accountId/');
      
      return BankAccount.fromJson(response.data as Map<String, dynamic>);

    } catch (e) {
      if (kDebugMode) {
        print('Get bank account error: $e');
      }
      return null;
    }
  }

  /// Create a new bank account
  Future<BankAccount?> createBankAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required String accountType,
    String? bvn,
    String? sortCode,
  }) async {
    try {
      final data = {
        'bank_name': bankName,
        'bank_code': bankCode,
        'account_number': accountNumber,
        'account_name': accountName,
        'account_type': accountType,
      };

      if (bvn != null && bvn.isNotEmpty) {
        data['bvn'] = bvn;
      }

      if (sortCode != null && sortCode.isNotEmpty) {
        data['sort_code'] = sortCode;
      }

      final response = await _apiService.post(
        '/riders/bank-accounts/',
        data: data,
      );

      return BankAccount.fromJson(response.data as Map<String, dynamic>);

    } catch (e) {
      if (kDebugMode) {
        print('Create bank account error: $e');
      }
      rethrow;
    }
  }

  /// Update an existing bank account
  Future<BankAccount?> updateBankAccount(
    int accountId, {
    String? bankName,
    String? accountName,
    String? accountType,
    String? bvn,
    String? sortCode,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (bankName != null) data['bank_name'] = bankName;
      if (accountName != null) data['account_name'] = accountName;
      if (accountType != null) data['account_type'] = accountType;
      if (bvn != null) data['bvn'] = bvn;
      if (sortCode != null) data['sort_code'] = sortCode;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _apiService.patch(
        '/riders/bank-accounts/$accountId/',
        data: data,
      );

      return BankAccount.fromJson(response.data as Map<String, dynamic>);

    } catch (e) {
      if (kDebugMode) {
        print('Update bank account error: $e');
      }
      rethrow;
    }
  }

  /// Delete a bank account
  Future<bool> deleteBankAccount(int accountId) async {
    try {
      await _apiService.delete('/riders/bank-accounts/$accountId/');
      return true;

    } catch (e) {
      if (kDebugMode) {
        print('Delete bank account error: $e');
      }
      rethrow;
    }
  }

  /// Get the primary bank account
  Future<BankAccount?> getPrimaryAccount() async {
    try {
      final response = await _apiService.get('/riders/bank-accounts/primary/');
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true && data['account'] != null) {
        return BankAccount.fromJson(data['account'] as Map<String, dynamic>);
      }
      
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('Get primary account error: $e');
      }
      return null;
    }
  }

  /// Set a bank account as primary
  Future<bool> setPrimaryAccount(int accountId) async {
    try {
      final response = await _apiService.post(
        '/riders/bank-accounts/set-primary/',
        data: {'account_id': accountId},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;

    } catch (e) {
      if (kDebugMode) {
        print('Set primary account error: $e');
      }
      rethrow;
    }
  }

  /// Get bank account statistics
  Future<BankAccountStats?> getBankAccountStats() async {
    try {
      final response = await _apiService.get('/riders/bank-accounts/stats/');
      
      return BankAccountStats.fromJson(response.data as Map<String, dynamic>);

    } catch (e) {
      if (kDebugMode) {
        print('Get bank account stats error: $e');
      }
      return null;
    }
  }

  /// Validate bank account details before creation
  Future<BankValidationResult?> validateBankDetails({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '/riders/bank-accounts/validate/',
        data: {
          'bank_code': bankCode,
          'account_number': accountNumber,
        },
      );

      return BankValidationResult.fromJson(response.data as Map<String, dynamic>);

    } catch (e) {
      if (kDebugMode) {
        print('Validate bank details error: $e');
      }
      rethrow;
    }
  }

  /// Resend verification for a bank account
  Future<bool> resendVerification(int accountId) async {
    try {
      final response = await _apiService.post(
        '/riders/bank-accounts/$accountId/resend-verification/',
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;

    } catch (e) {
      if (kDebugMode) {
        print('Resend verification error: $e');
      }
      rethrow;
    }
  }

  /// Get verification status for a bank account
  Future<Map<String, dynamic>?> getVerificationStatus(int accountId) async {
    try {
      final response = await _apiService.get(
        '/riders/bank-accounts/$accountId/verification-status/',
      );

      return response.data as Map<String, dynamic>;

    } catch (e) {
      if (kDebugMode) {
        print('Get verification status error: $e');
      }
      return null;
    }
  }

  /// Get verification logs for all accounts
  Future<List<BankVerificationLog>> getVerificationLogs() async {
    try {
      final response = await _apiService.get('/riders/bank-accounts/verification-logs/');
      
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> results = data['results'] ?? [];
      
      return results
          .map((log) => BankVerificationLog.fromJson(log as Map<String, dynamic>))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('Get verification logs error: $e');
      }
      
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Helper method to get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error is Map<String, dynamic>) {
      // Handle validation errors
      final List<String> errors = [];
      
      error.forEach((key, value) {
        if (value is List) {
          errors.addAll(value.map((v) => v.toString()));
        } else {
          errors.add(value.toString());
        }
      });
      
      return errors.isNotEmpty ? errors.first : 'An error occurred';
    } else {
      return error.toString();
    }
  }

  /// Helper method to format account number for display
  String maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    
    final visibleDigits = accountNumber.substring(accountNumber.length - 4);
    final maskedPart = '*' * (accountNumber.length - 4);
    
    return maskedPart + visibleDigits;
  }

  /// Helper method to validate account number format
  bool isValidAccountNumber(String accountNumber) {
    // Remove any non-numeric characters
    final cleaned = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check length (Nigerian banks typically use 10 digits)
    return cleaned.length >= 10 && cleaned.length <= 20;
  }

  /// Helper method to validate BVN format
  bool isValidBVN(String bvn) {
    // Remove any non-numeric characters
    final cleaned = bvn.replaceAll(RegExp(r'[^0-9]'), '');
    
    // BVN must be exactly 11 digits
    return cleaned.length == 11;
  }

  /// Helper method to validate bank code format
  bool isValidBankCode(String bankCode) {
    // Remove any non-numeric characters
    final cleaned = bankCode.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Bank codes are typically 3-4 digits
    return cleaned.length >= 3 && cleaned.length <= 10;
  }

  /// Helper method to find bank by code from list
  SupportedBank? findBankByCode(List<SupportedBank> banks, String code) {
    try {
      return banks.firstWhere((bank) => bank.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to search banks by name
  List<SupportedBank> searchBanks(List<SupportedBank> banks, String query) {
    if (query.isEmpty) return banks;
    
    final lowerQuery = query.toLowerCase();
    
    return banks.where((bank) =>
        bank.name.toLowerCase().contains(lowerQuery) ||
        bank.shortName.toLowerCase().contains(lowerQuery) ||
        bank.code.contains(query)
    ).toList();
  }
}