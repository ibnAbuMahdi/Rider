import 'dart:math' as math;
import '../models/campaign.dart';

/// Utility class for calculating earnings across multiple geofences
/// Supports all rate types and provides detailed breakdowns
class GeofenceEarningsCalculator {
  
  /// Calculate total earnings across all geofences for a given session
  static Map<String, dynamic> calculateSessionEarnings({
    required Map<String, double> geofenceDistances, // Distance in meters per geofence
    required Map<String, Duration> geofenceDurations, // Time spent per geofence
    required List<Geofence> geofences,
  }) {
    final results = <String, dynamic>{};
    final geofenceBreakdown = <String, Map<String, dynamic>>{};
    double totalEarnings = 0.0;
    double totalDistanceKm = 0.0;
    Duration totalDuration = Duration.zero;
    
    for (final geofence in geofences) {
      final geofenceId = geofence.id;
      final distanceMeters = geofenceDistances[geofenceId] ?? 0.0;
      final duration = geofenceDurations[geofenceId] ?? Duration.zero;
      
      final geofenceEarnings = _calculateGeofenceEarnings(
        geofence: geofence,
        distanceMeters: distanceMeters,
        duration: duration,
      );
      
      geofenceBreakdown[geofenceId ?? 'unknown'] = {
        'geofence_name': geofence.name,
        'rate_type': geofence.rateType,
        'distance_km': distanceMeters / 1000.0,
        'duration_minutes': duration.inMinutes,
        'earnings': geofenceEarnings,
        'rate_details': _getRateDetails(geofence),
        'performance_data': geofence.performanceSummary,
        'target_demographics': geofence.targetDemographics,
      };
      
      totalEarnings += geofenceEarnings;
      totalDistanceKm += distanceMeters / 1000.0;
      totalDuration += duration;
    }
    
    results['total_earnings'] = totalEarnings;
    results['total_distance_km'] = totalDistanceKm;
    results['total_duration_minutes'] = totalDuration.inMinutes;
    results['geofence_breakdown'] = geofenceBreakdown;
    results['average_hourly_rate'] = totalDuration.inHours > 0 
        ? totalEarnings / totalDuration.inHours 
        : 0.0;
    results['average_km_rate'] = totalDistanceKm > 0 
        ? totalEarnings / totalDistanceKm 
        : 0.0;
    
    return results;
  }
  
  /// Calculate earnings for a specific geofence based on rate type
  static double _calculateGeofenceEarnings({
    required Geofence geofence,
    required double distanceMeters,
    required Duration duration,
  }) {
    final distanceKm = distanceMeters / 1000.0;
    final hoursActive = duration.inMilliseconds / (1000 * 60 * 60);
    
    switch (geofence.rateType) {
      case 'per_km':
        return (geofence.ratePerKm ?? 0.0) * distanceKm;
      
      case 'per_hour':
        return (geofence.ratePerHour ?? 0.0) * hoursActive;
      
      case 'fixed_daily':
        // For fixed daily, calculate proportional amount based on time spent
        // vs target coverage hours
        final targetHours = (geofence.targetCoverageHours ?? 0).toDouble();
        if (targetHours > 0) {
          final proportion = math.min(1.0, hoursActive / targetHours);
          return (geofence.fixedDailyRate ?? 0.0) * proportion;
        }
        return geofence.fixedDailyRate ?? 0.0;
      
      case 'hybrid':
        final kmEarnings = (geofence.ratePerKm ?? 0.0) * distanceKm;
        final hourEarnings = (geofence.ratePerHour ?? 0.0) * hoursActive;
        return kmEarnings + hourEarnings;
      
      default:
        return 0.0;
    }
  }
  
  /// Get rate details for display purposes
  static Map<String, dynamic> _getRateDetails(Geofence geofence) {
    return {
      'rate_per_km': geofence.ratePerKm,
      'rate_per_hour': geofence.ratePerHour,
      'fixed_daily_rate': geofence.fixedDailyRate,
      'target_coverage_hours': geofence.targetCoverageHours,
      'description': geofence.description,
      'area_type': geofence.areaType,
      'special_instructions': geofence.specialInstructions,
    };
  }
  
  /// Calculate potential earnings for different scenarios
  static Map<String, double> calculatePotentialEarnings({
    required Geofence geofence,
    double distanceKm = 50.0, // Default daily distance
    double hoursActive = 8.0, // Default working hours
  }) {
    final scenarios = <String, double>{};
    
    switch (geofence.rateType) {
      case 'per_km':
        scenarios['conservative'] = (geofence.ratePerKm ?? 0.0) * (distanceKm * 0.7);
        scenarios['realistic'] = (geofence.ratePerKm ?? 0.0) * distanceKm;
        scenarios['optimistic'] = (geofence.ratePerKm ?? 0.0) * (distanceKm * 1.3);
        break;
        
      case 'per_hour':
        scenarios['conservative'] = (geofence.ratePerHour ?? 0.0) * (hoursActive * 0.7);
        scenarios['realistic'] = (geofence.ratePerHour ?? 0.0) * hoursActive;
        scenarios['optimistic'] = (geofence.ratePerHour ?? 0.0) * (hoursActive * 1.3);
        break;
        
      case 'fixed_daily':
        scenarios['conservative'] = (geofence.fixedDailyRate ?? 0.0) * 0.8;
        scenarios['realistic'] = geofence.fixedDailyRate ?? 0.0;
        scenarios['optimistic'] = geofence.fixedDailyRate ?? 0.0;
        break;
        
      case 'hybrid':
        final baseKm = (geofence.ratePerKm ?? 0.0) * distanceKm;
        final baseHour = (geofence.ratePerHour ?? 0.0) * hoursActive;
        scenarios['conservative'] = (baseKm + baseHour) * 0.7;
        scenarios['realistic'] = baseKm + baseHour;
        scenarios['optimistic'] = (baseKm + baseHour) * 1.3;
        break;
    }
    
    return scenarios;
  }
  
  /// Find the most profitable geofence for given conditions
  static Map<String, dynamic> findMostProfitableGeofence({
    required List<Geofence> geofences,
    double expectedDistanceKm = 50.0,
    double expectedHours = 8.0,
  }) {
    if (geofences.isEmpty) {
      return {'geofence': null, 'earnings': 0.0, 'reason': 'No geofences available'};
    }
    
    Geofence? bestGeofence;
    double maxEarnings = 0.0;
    final geofenceComparison = <String, double>{};
    
    for (final geofence in geofences) {
      if (!geofence.canAcceptRiders) continue;
      
      final potentialEarnings = calculatePotentialEarnings(
        geofence: geofence,
        distanceKm: expectedDistanceKm,
        hoursActive: expectedHours,
      );
      
      final realisticEarnings = potentialEarnings['realistic'] ?? 0.0;
      geofenceComparison[geofence.id ?? 'unknown_geofence'] = realisticEarnings;
      
      if (realisticEarnings > maxEarnings) {
        maxEarnings = realisticEarnings;
        bestGeofence = geofence;
      }
    }
    
    return {
      'geofence': bestGeofence,
      'earnings': maxEarnings,
      'all_comparisons': geofenceComparison,
      'reason': bestGeofence != null 
          ? 'Highest potential earnings: ₦${maxEarnings.toStringAsFixed(2)}'
          : 'No available geofences',
    };
  }
  
  /// Calculate efficiency metrics for geofence performance
  static Map<String, dynamic> calculateEfficiencyMetrics({
    required Map<String, double> geofenceDistances,
    required Map<String, Duration> geofenceDurations,
    required Map<String, double> geofenceEarnings,
    required List<Geofence> geofences,
  }) {
    final metrics = <String, dynamic>{};
    final geofenceMetrics = <String, Map<String, double>>{};
    
    double totalEarnings = 0.0;
    double totalDistanceKm = 0.0;
    Duration totalDuration = Duration.zero;
    
    for (final geofence in geofences) {
      final geofenceId = geofence.id;
      final distance = geofenceDistances[geofenceId] ?? 0.0;
      final duration = geofenceDurations[geofenceId] ?? Duration.zero;
      final earnings = geofenceEarnings[geofenceId] ?? 0.0;
      
      final distanceKm = distance / 1000.0;
      final hours = duration.inMilliseconds / (1000 * 60 * 60);
      
      geofenceMetrics[geofenceId ?? 'unknown'] = {
        'earnings_per_km': distanceKm > 0 ? earnings / distanceKm : 0.0,
        'earnings_per_hour': hours > 0 ? earnings / hours : 0.0,
        'time_efficiency': _calculateTimeEfficiency(geofence, duration),
        'distance_efficiency': _calculateDistanceEfficiency(geofence, distanceKm),
      };
      
      totalEarnings += earnings;
      totalDistanceKm += distanceKm;
      totalDuration += duration;
    }
    
    metrics['total_earnings'] = totalEarnings;
    metrics['overall_earnings_per_km'] = totalDistanceKm > 0 ? totalEarnings / totalDistanceKm : 0.0;
    metrics['overall_earnings_per_hour'] = totalDuration.inHours > 0 ? totalEarnings / totalDuration.inHours : 0.0;
    metrics['geofence_metrics'] = geofenceMetrics;
    metrics['session_efficiency_score'] = _calculateSessionEfficiency(geofenceMetrics);
    
    return metrics;
  }
  
  /// Calculate time efficiency for a geofence
  static double _calculateTimeEfficiency(Geofence geofence, Duration actualTime) {
    final targetMinutes = (geofence.targetCoverageHours ?? 0) * 60;
    final actualMinutes = actualTime.inMinutes;
    
    if (targetMinutes == 0) return 1.0;
    
    // Efficiency is how close we are to the target (1.0 = perfect, <1.0 = under, >1.0 = over)
    return actualMinutes / targetMinutes;
  }
  
  /// Calculate distance efficiency for a geofence
  static double _calculateDistanceEfficiency(Geofence geofence, double actualDistanceKm) {
    // Assume 50km is the target daily distance for per_km rates
    const targetDistanceKm = 50.0;
    
    if (geofence.rateType != 'per_km' && geofence.rateType != 'hybrid') {
      return 1.0; // Distance doesn't matter for these rate types
    }
    
    return actualDistanceKm / targetDistanceKm;
  }
  
  /// Calculate overall session efficiency score
  static double _calculateSessionEfficiency(Map<String, Map<String, double>> geofenceMetrics) {
    if (geofenceMetrics.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int count = 0;
    
    for (final metrics in geofenceMetrics.values) {
      final timeEff = metrics['time_efficiency'] ?? 0.0;
      final distanceEff = metrics['distance_efficiency'] ?? 0.0;
      
      // Average time and distance efficiency, capped at 1.0 for scoring
      final geofenceScore = (math.min(1.0, timeEff) + math.min(1.0, distanceEff)) / 2;
      totalScore += geofenceScore;
      count++;
    }
    
    return count > 0 ? totalScore / count : 0.0;
  }
  
  /// Generate earnings report for a session
  static Map<String, dynamic> generateEarningsReport({
    required Map<String, double> geofenceDistances,
    required Map<String, Duration> geofenceDurations,
    required List<Geofence> geofences,
    DateTime? sessionStart,
    DateTime? sessionEnd,
  }) {
    final sessionEarnings = calculateSessionEarnings(
      geofenceDistances: geofenceDistances,
      geofenceDurations: geofenceDurations,
      geofences: geofences,
    );
    
    final geofenceEarnings = <String, double>{};
    for (final entry in sessionEarnings['geofence_breakdown'].entries) {
      geofenceEarnings[entry.key] = entry.value['earnings'];
    }
    
    final efficiencyMetrics = calculateEfficiencyMetrics(
      geofenceDistances: geofenceDistances,
      geofenceDurations: geofenceDurations,
      geofenceEarnings: geofenceEarnings,
      geofences: geofences,
    );
    
    return {
      'session_summary': {
        'start_time': sessionStart?.toIso8601String(),
        'end_time': sessionEnd?.toIso8601String(),
        'duration_minutes': sessionEnd != null && sessionStart != null 
            ? sessionEnd.difference(sessionStart).inMinutes 
            : sessionEarnings['total_duration_minutes'],
        'total_earnings': sessionEarnings['total_earnings'],
        'total_distance_km': sessionEarnings['total_distance_km'],
        'geofences_visited': geofences.length,
      },
      'earnings_breakdown': sessionEarnings['geofence_breakdown'],
      'efficiency_metrics': efficiencyMetrics,
      'performance_summary': {
        'average_hourly_rate': sessionEarnings['average_hourly_rate'],
        'average_km_rate': sessionEarnings['average_km_rate'],
        'efficiency_score': efficiencyMetrics['session_efficiency_score'],
        'best_performing_geofence': _findBestPerformingGeofence(
          sessionEarnings['geofence_breakdown']
        ),
      },
    };
  }
  
  /// Find the best performing geofence from session data
  static Map<String, dynamic>? _findBestPerformingGeofence(Map<String, dynamic> breakdown) {
    if (breakdown.isEmpty) return null;
    
    String? bestGeofenceId;
    double maxEarnings = 0.0;
    
    for (final entry in breakdown.entries) {
      final earnings = entry.value['earnings'] as double;
      if (earnings > maxEarnings) {
        maxEarnings = earnings;
        bestGeofenceId = entry.key;
      }
    }
    
    if (bestGeofenceId != null) {
      return {
        'geofence_id': bestGeofenceId,
        'geofence_name': breakdown[bestGeofenceId]['geofence_name'],
        'earnings': maxEarnings,
        'rate_type': breakdown[bestGeofenceId]['rate_type'],
      };
    }
    
    return null;
  }
}