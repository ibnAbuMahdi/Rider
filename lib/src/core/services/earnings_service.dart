import 'package:flutter/foundation.dart';
import '../models/earning.dart';
import '../models/payment_summary.dart';
import '../models/campaign.dart';
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

  // Get earnings by campaign with geofence breakdown
  Future<Map<String, dynamic>?> getCampaignEarnings(String campaignId) async {
    try {
      final response = await _apiService.get('/rider/campaigns/$campaignId/earnings/');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> earningsJson = data['earnings'] ?? [];
        final List<dynamic> geofenceEarningsJson = data['geofence_earnings'] ?? [];
        
        return {
          'earnings': earningsJson.map((json) => Earning.fromJson(json)).toList(),
          'geofence_earnings': geofenceEarningsJson,
          'total_amount': data['total_amount'] ?? 0.0,
          'hours_worked': data['hours_worked'] ?? 0.0,
          'verifications_count': data['verifications_count'] ?? 0,
          'total_distance_km': data['total_distance_km'] ?? 0.0,
          'geofence_breakdown': data['geofence_breakdown'] ?? {},
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
  
  // Get earnings breakdown by geofence for a specific campaign
  Future<Map<String, dynamic>?> getGeofenceEarningsBreakdown(String campaignId) async {
    try {
      final response = await _apiService.get('/rider/campaigns/$campaignId/geofence-earnings/');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'geofences': data['geofences'] ?? [],
          'total_earnings': data['total_earnings'] ?? 0.0,
          'earnings_by_rate_type': data['earnings_by_rate_type'] ?? {},
          'most_profitable_geofence': data['most_profitable_geofence'],
          'time_breakdown': data['time_breakdown'] ?? {},
          'distance_breakdown': data['distance_breakdown'] ?? {},
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get geofence earnings breakdown: $e');
      }
      return null;
    }
  }
  
  // Calculate potential earnings for a geofence
  Map<String, double> calculatePotentialEarnings({
    required String rateType,
    required double ratePerKm,
    required double ratePerHour,
    required double fixedDailyRate,
    double estimatedDistanceKm = 50.0, // Default daily distance
    double estimatedHours = 8.0, // Default working hours
  }) {
    final results = <String, double>{};
    
    switch (rateType) {
      case 'per_km':
        results['daily'] = ratePerKm * estimatedDistanceKm;
        results['weekly'] = results['daily']! * 7;
        results['monthly'] = results['daily']! * 30;
        break;
        
      case 'per_hour':
        results['daily'] = ratePerHour * estimatedHours;
        results['weekly'] = results['daily']! * 7;
        results['monthly'] = results['daily']! * 30;
        break;
        
      case 'fixed_daily':
        results['daily'] = fixedDailyRate;
        results['weekly'] = fixedDailyRate * 7;
        results['monthly'] = fixedDailyRate * 30;
        break;
        
      case 'hybrid':
        final dailyKmEarnings = ratePerKm * estimatedDistanceKm;
        final dailyHourEarnings = ratePerHour * estimatedHours;
        results['daily'] = dailyKmEarnings + dailyHourEarnings;
        results['weekly'] = results['daily']! * 7;
        results['monthly'] = results['daily']! * 30;
        break;
        
      default:
        results['daily'] = 0.0;
        results['weekly'] = 0.0;
        results['monthly'] = 0.0;
    }
    
    return results;
  }
  
  // Compare earnings across geofences
  Map<String, dynamic> compareGeofenceEarnings(List<Map<String, dynamic>> geofences) {
    if (geofences.isEmpty) return {};
    
    double totalEarnings = 0.0;
    double maxEarnings = 0.0;
    double minEarnings = double.infinity;
    String? bestGeofenceId;
    String? worstGeofenceId;
    
    final earningsByRateType = <String, double>{
      'per_km': 0.0,
      'per_hour': 0.0,
      'fixed_daily': 0.0,
      'hybrid': 0.0,
    };
    
    for (final geofence in geofences) {
      final earnings = (geofence['earnings'] as num?)?.toDouble() ?? 0.0;
      final rateType = geofence['rate_type'] as String? ?? 'per_km';
      final geofenceId = geofence['geofence_id'] as String? ?? '';
      
      totalEarnings += earnings;
      earningsByRateType[rateType] = (earningsByRateType[rateType] ?? 0.0) + earnings;
      
      if (earnings > maxEarnings) {
        maxEarnings = earnings;
        bestGeofenceId = geofenceId;
      }
      
      if (earnings < minEarnings) {
        minEarnings = earnings;
        worstGeofenceId = geofenceId;
      }
    }
    
    return {
      'total_earnings': totalEarnings,
      'average_earnings': geofences.isNotEmpty ? totalEarnings / geofences.length : 0.0,
      'best_geofence': {
        'id': bestGeofenceId,
        'earnings': maxEarnings,
      },
      'worst_geofence': {
        'id': worstGeofenceId,
        'earnings': minEarnings == double.infinity ? 0.0 : minEarnings,
      },
      'earnings_by_rate_type': earningsByRateType,
      'geofence_count': geofences.length,
    };
  }
  
  // Get real-time earnings for active campaign geofences
  Future<Map<String, dynamic>?> getCurrentGeofenceEarnings() async {
    try {
      final response = await _apiService.get('/rider/current-geofence-earnings/');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'current_geofence': data['current_geofence'],
          'earnings_today': data['earnings_today'] ?? 0.0,
          'distance_today_km': data['distance_today_km'] ?? 0.0,
          'hours_today': data['hours_today'] ?? 0.0,
          'geofence_earnings_breakdown': data['geofence_earnings_breakdown'] ?? {},
          'projected_daily_earnings': data['projected_daily_earnings'] ?? 0.0,
          'last_updated': data['last_updated'],
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get current geofence earnings: $e');
      }
      return null;
    }
  }
  
  // Submit earnings data from mobile tracking
  Future<bool> submitGeofenceEarnings({
    required String campaignId,
    required Map<String, Map<String, dynamic>> geofenceEarnings,
    required double totalDistance,
    required Duration totalTime,
  }) async {
    try {
      final requestData = {
        'campaign_id': campaignId,
        'geofence_earnings': geofenceEarnings,
        'total_distance_km': totalDistance / 1000.0, // Convert to km
        'total_time_minutes': totalTime.inMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await _apiService.post('/rider/submit-geofence-earnings/', data: requestData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('💰 Geofence earnings submitted successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to submit geofence earnings: $e');
      }
      return false;
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