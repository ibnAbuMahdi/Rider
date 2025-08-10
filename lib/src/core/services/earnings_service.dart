import 'package:flutter/foundation.dart';
import '../models/earning.dart';
import '../models/payment_summary.dart';
import '../models/campaign_earnings.dart';
import '../models/location_record.dart'; // For EarningsRecord
import 'api_service.dart';
import 'location_api_service.dart';

class EarningsService {
  final ApiService _apiService;
  final LocationApiService _locationApiService;

  EarningsService(this._apiService, this._locationApiService);

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

  // New methods using backend tracking system

  // Get tracking-based earnings calculations
  Future<List<Map<String, dynamic>>> getTrackingEarnings({
    DateTime? startDate,
    DateTime? endDate,
    String? earningsType,
  }) async {
    try {
      return await _locationApiService.calculateEarnings(
        mobileId: '', // Will be populated by the API call
        geofenceId: 0, // Will be filtered by the API
        earningsType: earningsType ?? 'all',
        distanceKm: 0.0,
        durationHours: 0.0,
        verificationsCompleted: 0,
        earnedAt: DateTime.now(),
      ).then((result) {
        if (result['success'] == true) {
          return [result];
        }
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get tracking earnings: $e');
      }
      return [];
    }
  }

  // Calculate earnings for a completed session
  Future<Map<String, dynamic>> calculateSessionEarnings({
    required String mobileId,
    required int geofenceId,
    required String earningsType,
    required double distanceKm,
    required double durationHours,
    required int verificationsCompleted,
    required DateTime earnedAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _locationApiService.calculateEarnings(
        mobileId: mobileId,
        geofenceId: geofenceId,
        earningsType: earningsType,
        distanceKm: distanceKm,
        durationHours: durationHours,
        verificationsCompleted: verificationsCompleted,
        earnedAt: earnedAt,
        metadata: metadata,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to calculate session earnings: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get comprehensive tracking statistics
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      return await _locationApiService.getTrackingStats();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get tracking stats: $e');
      }
      return {
        'today_distance': 0.0,
        'today_earnings': 0.0,
        'today_sessions': 0,
        'week_distance': 0.0,
        'week_earnings': 0.0,
        'month_distance': 0.0,
        'month_earnings': 0.0,
        'active_geofences': <String>[],
        'pending_sync_count': 0,
        'last_sync': null,
      };
    }
  }

  // Get earnings calculations from tracking backend
  Future<List<Map<String, dynamic>>> getBackendEarningsCalculations({
    DateTime? startDate,
    DateTime? endDate,
    String? earningsType,
  }) async {
    try {
      return await _apiService.getEarningsCalculations(queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (earningsType != null) 'earnings_type': earningsType,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get backend earnings calculations: $e');
      }
      return [];
    }
  }

  // Get rider work sessions with earnings data
  Future<List<Map<String, dynamic>>> getWorkSessions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      return await _apiService.getRiderSessions(queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (status != null) 'status': status,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get work sessions: $e');
      }
      return [];
    }
  }

  // Get daily tracking summaries with earnings breakdown
  Future<List<Map<String, dynamic>>> getDailyEarningsSummaries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _apiService.getDailyTrackingSummaries(queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get daily earnings summaries: $e');
      }
      return [];
    }
  }

  // Validate mobile earnings against backend calculations
  Future<Map<String, dynamic>> validateEarnings({
    required String mobileEarningId,
    required double mobileAmount,
    required String earningsType,
    required double distanceKm,
    required double durationHours,
    required int verificationsCompleted,
    required DateTime earnedAt,
  }) async {
    try {
      // Get corresponding backend calculation
      final backendResult = await calculateSessionEarnings(
        mobileId: mobileEarningId,
        geofenceId: 0, // Will be determined by backend
        earningsType: earningsType,
        distanceKm: distanceKm,
        durationHours: durationHours,
        verificationsCompleted: verificationsCompleted,
        earnedAt: earnedAt,
      );

      if (backendResult['success'] == true) {
        final backendAmount = (backendResult['amount'] as num?)?.toDouble() ?? 0.0;
        final difference = (mobileAmount - backendAmount).abs();
        final tolerance = mobileAmount * 0.01; // 1% tolerance

        return {
          'is_valid': difference <= tolerance,
          'mobile_amount': mobileAmount,
          'backend_amount': backendAmount,
          'difference': difference,
          'tolerance': tolerance,
          'discrepancy_percentage': mobileAmount > 0 ? (difference / mobileAmount) * 100 : 0.0,
          'backend_result': backendResult,
        };
      }

      return {
        'is_valid': false,
        'error': 'Backend validation failed',
        'backend_result': backendResult,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to validate earnings: $e');
      }
      return {
        'is_valid': false,
        'error': e.toString(),
      };
    }
  }

  // Sync mobile earnings with backend tracking system
  Future<Map<String, dynamic>> syncMobileEarningsWithBackend(List<Map<String, dynamic>> mobileEarnings) async {
    try {
      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      for (final earning in mobileEarnings) {
        try {
          final result = await calculateSessionEarnings(
            mobileId: earning['id'] as String,
            geofenceId: earning['geofence_id'] as int? ?? 0,
            earningsType: earning['earnings_type'] as String? ?? 'distance',
            distanceKm: (earning['distance_km'] as num?)?.toDouble() ?? 0.0,
            durationHours: (earning['duration_hours'] as num?)?.toDouble() ?? 0.0,
            verificationsCompleted: earning['verifications_completed'] as int? ?? 0,
            earnedAt: DateTime.parse(earning['earned_at'] as String),
            metadata: earning['metadata'] as Map<String, dynamic>?,
          );

          if (result['success'] == true) {
            successCount++;
          } else {
            failureCount++;
            errors.add('${earning['id']}: ${result['error']}');
          }
        } catch (e) {
          failureCount++;
          errors.add('${earning['id']}: $e');
        }
      }

      return {
        'success': failureCount == 0,
        'total_earnings': mobileEarnings.length,
        'success_count': successCount,
        'failure_count': failureCount,
        'errors': errors,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to sync mobile earnings with backend: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'success_count': 0,
        'failure_count': mobileEarnings.length,
      };
    }
  }

  // Enhanced methods for new earnings section design

  /// Get comprehensive earnings overview with analytics
  Future<EarningsOverview?> getEarningsOverview() async {
    try {
      final response = await _apiService.get('/rider/earnings-overview/');

      if (response.statusCode == 200) {
        return EarningsOverview.fromJson(response.data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings overview: $e');
      }
      return null;
    }
  }

  /// Get campaign earnings summaries (grouped by campaign)
  Future<List<CampaignSummary>?> getCampaignSummaries() async {
    try {
      final response = await _apiService.get('/rider/campaign-summaries/');

      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data['results'] ?? response.data;
        return campaignsJson
            .map((json) => CampaignSummary.fromJson(json))
            .toList();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get campaign summaries: $e');
      }
      return null;
    }
  }

  /// Get geofence assignment earnings (individual assignments)
  Future<List<CampaignEarnings>?> getGeofenceAssignmentEarnings({
    String? campaignId,
    String? geofenceId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (campaignId != null) queryParams['campaign_id'] = campaignId;
      if (geofenceId != null) queryParams['geofence_id'] = geofenceId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get('/rider/geofence-assignment-earnings/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> assignmentsJson = response.data['results'] ?? response.data;
        return assignmentsJson
            .map((json) => CampaignEarnings.fromJson(json))
            .toList();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get geofence assignment earnings: $e');
      }
      return null;
    }
  }

  /// Get detailed campaign earnings with geofence breakdown
  Future<Map<String, dynamic>?> getCampaignEarningsDetail(String campaignId) async {
    try {
      final response = await _apiService.get('/rider/campaigns/$campaignId/earnings-detail/');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'campaign_earnings': CampaignEarnings.fromJson(data['campaign']),
          'recent_earnings': (data['recent_earnings'] as List?)
              ?.map((json) => Earning.fromJson(json))
              .toList() ?? [],
          'geofence_breakdown': data['geofence_breakdown'] ?? {},
          'weekly_trend': data['weekly_trend'] ?? [],
          'monthly_stats': data['monthly_stats'] ?? {},
          'performance_metrics': data['performance_metrics'] ?? {},
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get campaign earnings detail: $e');
      }
      return null;
    }
  }

  /// Get earnings trends and analytics
  Future<Map<String, dynamic>?> getEarningsTrends({
    String period = 'month',
    int limit = 30,
  }) async {
    try {
      final response = await _apiService.get('/rider/earnings-trends/', queryParameters: {
        'period': period,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'daily_trends': data['daily_trends'] ?? [],
          'weekly_trends': data['weekly_trends'] ?? [],
          'monthly_trends': data['monthly_trends'] ?? [],
          'growth_rates': data['growth_rates'] ?? {},
          'peak_earning_times': data['peak_earning_times'] ?? {},
          'top_performing_campaigns': data['top_performing_campaigns'] ?? [],
          'earnings_goals': data['earnings_goals'] ?? {},
          'projections': data['projections'] ?? {},
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings trends: $e');
      }
      return null;
    }
  }

  /// Get earnings summary for dashboard cards
  Future<Map<String, dynamic>?> getEarningsSummaryForCards() async {
    try {
      // Get both overview and campaign summaries in parallel
      final results = await Future.wait([
        getEarningsOverview(),
        getCampaignSummaries(),
        getGeofenceAssignmentEarnings(status: 'active', limit: 5), // Recent active assignments
      ]);

      final overview = results[0] as EarningsOverview?;
      final campaignSummaries = results[1] as List<CampaignSummary>?;
      final activeAssignments = results[2] as List<CampaignEarnings>?;

      if (overview != null) {
        return {
          'overview': overview,
          'campaign_summaries': campaignSummaries ?? [],
          'active_assignments': activeAssignments ?? [],
          'has_data': campaignSummaries?.isNotEmpty ?? false,
          'needs_refresh': overview.updatedAt.isBefore(
            DateTime.now().subtract(const Duration(hours: 1))
          ),
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings summary for cards: $e');
      }
      return null;
    }
  }

  /// Search earnings by campaign or geofence
  Future<List<Earning>?> searchEarnings({
    String? query,
    String? campaignId,
    String? geofenceId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (campaignId != null) queryParams['campaign_id'] = campaignId;
      if (geofenceId != null) queryParams['geofence_id'] = geofenceId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/rider/earnings/search/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> earningsJson = response.data['results'] ?? response.data;
        return earningsJson.map((json) => Earning.fromJson(json)).toList();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to search earnings: $e');
      }
      return null;
    }
  }

  /// Get earnings statistics for a specific period
  Future<Map<String, dynamic>?> getEarningsStats({
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'day', // 'day', 'week', 'month'
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'group_by': groupBy,
      };

      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/rider/earnings-stats/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings stats: $e');
      }
      return null;
    }
  }

  /// Export earnings data
  Future<Map<String, dynamic>?> exportEarningsData({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv', // 'csv', 'pdf', 'excel'
    List<String>? includeFields,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'format': format,
      };

      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (includeFields != null) queryParams['fields'] = includeFields.join(',');

      final response = await _apiService.get('/rider/earnings/export/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return {
          'download_url': response.data['download_url'],
          'file_name': response.data['file_name'],
          'expires_at': response.data['expires_at'],
          'file_size': response.data['file_size'],
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to export earnings data: $e');
      }
      return null;
    }
  }

  /// Get earnings goals and progress
  Future<Map<String, dynamic>?> getEarningsGoals() async {
    try {
      final response = await _apiService.get('/rider/earnings-goals/');

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get earnings goals: $e');
      }
      return null;
    }
  }

  /// Set earnings goal
  Future<bool> setEarningsGoal({
    required double amount,
    required String period, // 'weekly', 'monthly', 'yearly'
    String? description,
  }) async {
    try {
      final response = await _apiService.post('/rider/earnings-goals/', data: {
        'amount': amount,
        'period': period,
        'description': description,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('🎯 Earnings goal set successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set earnings goal: $e');
      }
      return false;
    }
  }

  /// Submit hourly tracking window to backend for earnings calculation
  Future<Map<String, dynamic>?> submitHourlyEarnings(EarningsRecord earningsRecord) async {
    try {
      final windowData = earningsRecord.metadata!;
      
      // Prepare tracking data from metadata
      final trackingData = {
        'samples': [], // Will be populated from stored tracking data
        'failure_events': [],
        'effective_minutes': windowData['effective_minutes'],
        'tracking_quality': windowData['tracking_quality'],
      };

      final requestData = {
        'window_id': earningsRecord.id,
        'geofence_id': windowData['geofence_id'],
        'window_start': windowData['window_start'],
        'tracking_data': trackingData,
      };

      final response = await _apiService.post('/tracking/hourly-tracking-window/', data: requestData);

      if (response.statusCode == 201) {
        final data = response.data;
        
        if (kDebugMode) {
          print('⏰ Hourly earnings submitted successfully: ₦${data['calculated_amount']}');
          print('⏰ Backend validation: ${data['backend_calculation']}');
        }

        return {
          'success': data['success'],
          'calculated_amount': data['calculated_amount'],
          'effective_minutes': data['effective_minutes'],
          'tracking_quality': data['tracking_quality'],
          'backend_calculation': data['backend_calculation'],
          'earnings_calculation_id': data['earnings_calculation_id'],
        };
      }

      if (kDebugMode) {
        print('❌ Failed to submit hourly earnings: ${response.statusCode}');
      }
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to submit hourly earnings: $e');
      }
      return null;
    }
  }

  /// Submit hourly tracking window with full location samples and assignment attribution
  Future<Map<String, dynamic>?> submitHourlyTrackingWindow({
    required String windowId,
    required String geofenceId,
    String? assignmentId,  // Add assignment ID for proper earnings attribution
    required DateTime windowStart,
    required List<Map<String, dynamic>> locationSamples,
    required List<Map<String, dynamic>> failureEvents,
    required double effectiveMinutes,
    required double trackingQuality,
  }) async {
    try {
      final requestData = {
        'window_id': windowId,
        'geofence_id': geofenceId,
        'window_start': windowStart.toIso8601String(),
        'tracking_data': {
          'samples': locationSamples,
          'failure_events': failureEvents,
          'effective_minutes': effectiveMinutes,
          'tracking_quality': trackingQuality,
        },
      };
      
      // Add assignment ID for proper earnings attribution
      if (assignmentId != null) {
        requestData['assignment_id'] = assignmentId;
      }

      final response = await _apiService.post('/tracking/hourly-tracking-window/', data: requestData);

      if (response.statusCode == 201) {
        final data = response.data;
        
        if (kDebugMode) {
          print('⏰ Hourly tracking window submitted: ${data['status']}');
          print('⏰ Calculated earnings: ₦${data['calculated_amount']}');
          print('⏰ Effective time: ${data['effective_minutes']} minutes');
          
          final backendCalc = data['backend_calculation'];
          print('⏰ Backend validation:');
          print('  - Rate: ₦${backendCalc['hourly_rate']}/hour');
          print('  - Billable: ${backendCalc['billable_minutes']} minutes');
          print('  - Working hours valid: ${backendCalc['working_hours_valid']}');
          print('  - Minimum time met: ${backendCalc['minimum_time_met']}');
          print('  - Minimum samples met: ${backendCalc['minimum_samples_met']}');
        }

        return data;
      }

      if (kDebugMode) {
        print('❌ Failed to submit hourly tracking window: ${response.statusCode} - ${response.data}');
      }
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to submit hourly tracking window: $e');
      }
      return null;
    }
  }
}