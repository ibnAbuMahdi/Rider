import 'package:flutter/foundation.dart';
import '../models/earning.dart';
import '../models/payment_summary.dart';
import 'api_service.dart';

class EarningsService {
  final ApiService _apiService;

  EarningsService(this._apiService);

  // Get rider's earnings with pagination
  Future<Map<String, dynamic>?> getEarnings({
    int page = 1,
    int limit = 20,
    String? status,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;
      if (campaignId != null) queryParams['campaign_id'] = campaignId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/rider/earnings/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> earningsJson = data['results'] ?? [];
        
        final earnings = earningsJson.map((json) => Earning.fromJson(json)).toList();
        final hasMore = data['next'] != null;

        return {
          'earnings': earnings,
          'has_more': hasMore,
          'total_count': data['count'] ?? 0,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings: $e');
      }
      return null;
    }
  }

  // Get payment summary
  Future<PaymentSummary?> getPaymentSummary() async {
    try {
      final response = await _apiService.get('/rider/payment-summary/');

      if (response.statusCode == 200) {
        return PaymentSummary.fromJson(response.data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get payment summary: $e');
      }
      return null;
    }
  }

  // Request payment withdrawal
  Future<bool> requestPayment({
    required double amount,
    required String paymentMethod,
    String? bankAccount,
    String? bankCode,
    String? phoneNumber,
    String? notes,
  }) async {
    try {
      final requestData = {
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
      };

      // Add method-specific fields
      if (paymentMethod == 'bank_transfer') {
        if (bankAccount != null) requestData['bank_account'] = bankAccount;
        if (bankCode != null) requestData['bank_code'] = bankCode;
      } else if (paymentMethod == 'mobile_money') {
        if (phoneNumber != null) requestData['phone_number'] = phoneNumber;
      }

      final response = await _apiService.post('/rider/payment-requests/', data: requestData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('💰 Payment request submitted successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to request payment: $e');
      }
      return false;
    }
  }

  // Get payment methods available to rider
  Future<List<Map<String, dynamic>>?> getPaymentMethods() async {
    try {
      final response = await _apiService.get('/rider/payment-methods/');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['results'] ?? response.data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get payment methods: $e');
      }
      return null;
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>?> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get('/rider/payment-history/', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['results'] ?? data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get payment history: $e');
      }
      return null;
    }
  }

  // Update payment method
  Future<bool> updatePaymentMethod({
    required String paymentMethod,
    String? bankAccount,
    String? bankCode,
    String? bankName,
    String? accountName,
    String? phoneNumber,
  }) async {
    try {
      final requestData = {
        'payment_method': paymentMethod,
      };

      if (paymentMethod == 'bank_transfer') {
        if (bankAccount != null) requestData['bank_account'] = bankAccount;
        if (bankCode != null) requestData['bank_code'] = bankCode;
        if (bankName != null) requestData['bank_name'] = bankName;
        if (accountName != null) requestData['account_name'] = accountName;
      } else if (paymentMethod == 'mobile_money') {
        if (phoneNumber != null) requestData['phone_number'] = phoneNumber;
      }

      final response = await _apiService.put('/rider/payment-method/', data: requestData);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('💳 Payment method updated successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update payment method: $e');
      }
      return false;
    }
  }

  // Get earnings by campaign
  Future<Map<String, dynamic>?> getCampaignEarnings(String campaignId) async {
    try {
      final response = await _apiService.get('/rider/campaigns/$campaignId/earnings/');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> earningsJson = data['earnings'] ?? [];
        
        return {
          'earnings': earningsJson.map((json) => Earning.fromJson(json)).toList(),
          'total_amount': data['total_amount'] ?? 0.0,
          'hours_worked': data['hours_worked'] ?? 0.0,
          'verifications_count': data['verifications_count'] ?? 0,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get campaign earnings: $e');
      }
      return null;
    }
  }

  // Get earning details
  Future<Earning?> getEarningDetails(String earningId) async {
    try {
      final response = await _apiService.get('/rider/earnings/$earningId/');

      if (response.statusCode == 200) {
        return Earning.fromJson(response.data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earning details: $e');
      }
      return null;
    }
  }

  // Report earning discrepancy
  Future<bool> reportEarningIssue({
    required String earningId,
    required String issueType,
    required String description,
    List<String>? attachments,
  }) async {
    try {
      final response = await _apiService.post('/rider/earning-issues/', 
        data: {
          'earning_id': earningId,
          'issue_type': issueType,
          'description': description,
          'attachments': attachments ?? [],
        });

      if (response.statusCode == 201) {
        if (kDebugMode) {
          print('📝 Earning issue reported successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to report earning issue: $e');
      }
      return false;
    }
  }
}