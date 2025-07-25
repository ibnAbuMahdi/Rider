import 'package:hive_flutter/hive_flutter.dart';
import '../models/rider.dart';
import '../models/campaign.dart';
import '../models/verification_request.dart';
import '../models/location_record.dart';
import '../constants/app_constants.dart';

class HiveService {
  static bool _isInitialized = false;
  
  // Boxes
  static late Box<Rider> _riderBox;
  static late Box<Campaign> _campaignBox;
  static late Box<VerificationRequest> _verificationBox;
  static late Box<LocationRecord> _locationBox;
  static late Box<EarningsRecord> _earningsBox;
  static late Box<PendingAction> _offlineQueueBox;
  static late Box<dynamic> _settingsBox;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Register adapters
    _registerAdapters();
    
    // Open boxes
    await _openBoxes();
    
    _isInitialized = true;
  }

  static void _registerAdapters() {
    // Register all Hive type adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RiderAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CampaignAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CampaignStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GeofenceAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(GeofenceShapeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(GeofencePointAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(CampaignRequirementsAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(VerificationRequestAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(VerificationStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(LocationRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(EarningsRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(EarningsTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(PaymentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(PendingActionAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ActionTypeAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    try {
      _riderBox = await Hive.openBox<Rider>(AppConstants.riderBox);
      _campaignBox = await Hive.openBox<Campaign>(AppConstants.campaignBox);
      _verificationBox = await Hive.openBox<VerificationRequest>(AppConstants.verificationBox);
      _locationBox = await Hive.openBox<LocationRecord>(AppConstants.locationBox);
      _earningsBox = await Hive.openBox<EarningsRecord>(AppConstants.earningsBox);
      _offlineQueueBox = await Hive.openBox<PendingAction>(AppConstants.offlineQueueBox);
      _settingsBox = await Hive.openBox('settings');
    } catch (e) {
      throw Exception('Failed to open Hive boxes: $e');
    }
  }

  // Rider operations
  static Future<void> saveRider(Rider rider) async {
    await _riderBox.put(AppConstants.riderDataKey, rider);
  }

  static Rider? getRider() {
    return _riderBox.get(AppConstants.riderDataKey);
  }

  static Future<void> clearRider() async {
    await _riderBox.delete(AppConstants.riderDataKey);
  }

  // Campaign operations
  static Future<void> saveCampaigns(List<Campaign> campaigns) async {
    await _campaignBox.clear();
    for (int i = 0; i < campaigns.length; i++) {
      await _campaignBox.put(i, campaigns[i]);
    }
  }

  static List<Campaign> getCampaigns() {
    return _campaignBox.values.toList();
  }

  static Future<void> saveCampaign(Campaign campaign) async {
    final campaigns = getCampaigns();
    final index = campaigns.indexWhere((c) => c.id != null && c.id == campaign.id);
    if (index >= 0) {
      await _campaignBox.putAt(index, campaign);
    } else {
      await _campaignBox.add(campaign);
    }
  }

  static Campaign? getCampaign(String campaignId) {
    return getCampaigns().where((c) => c.id == campaignId).firstOrNull;
  }

  // Verification operations
  static Future<void> saveVerificationRequest(VerificationRequest request) async {
    await _verificationBox.put(request.id, request);
  }

  static List<VerificationRequest> getVerificationRequests() {
    return _verificationBox.values.toList();
  }

  static List<VerificationRequest> getPendingVerifications() {
    return _verificationBox.values
        .where((v) => !v.isSynced)
        .toList();
  }

  static Future<void> updateVerificationRequest(VerificationRequest request) async {
    await _verificationBox.put(request.id, request);
  }

  static Future<void> clearOldVerifications() async {
    final now = DateTime.now();
    final oldKeys = <String>[];
    
    for (final entry in _verificationBox.toMap().entries) {
      final verification = entry.value;
      final daysDiff = now.difference(verification.createdAt).inDays;
      if (daysDiff > 30) { // Keep only last 30 days
        oldKeys.add(entry.key);
      }
    }
    
    await _verificationBox.deleteAll(oldKeys);
  }

  // Location operations
  static Future<void> saveLocationRecord(LocationRecord location) async {
    await _locationBox.put(location.id, location);
    
    // Clean old records if box gets too large
    if (_locationBox.length > AppConstants.maxLocationCacheSize) {
      await _cleanOldLocationRecords();
    }
  }

  static List<LocationRecord> getLocationRecords() {
    return _locationBox.values.toList();
  }

  static List<LocationRecord> getUnsyncedLocations() {
    return _locationBox.values
        .where((l) => !l.isSynced)
        .toList();
  }

  static Future<void> markLocationsSynced(List<String> locationIds) async {
    for (final id in locationIds) {
      final location = _locationBox.get(id);
      if (location != null) {
        await _locationBox.put(id, location.copyWith(isSynced: true));
      }
    }
  }

  static Future<void> _cleanOldLocationRecords() async {
    final locations = _locationBox.values.toList();
    locations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final toDelete = locations.skip(AppConstants.maxLocationCacheSize ~/ 2).toList();
    final keysToDelete = toDelete.map((l) => l.id).toList();
    
    await _locationBox.deleteAll(keysToDelete);
  }

  // Earnings operations
  static Future<void> saveEarningsRecord(EarningsRecord earning) async {
    await _earningsBox.put(earning.id, earning);
  }

  static List<EarningsRecord> getEarningsRecords() {
    return _earningsBox.values.toList();
  }

  static double getTotalEarnings() {
    return _earningsBox.values
        .where((e) => e.paymentStatus == PaymentStatus.completed)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getAvailableBalance() {
    return _earningsBox.values
        .where((e) => e.paymentStatus == PaymentStatus.completed)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getPendingBalance() {
    return _earningsBox.values
        .where((e) => e.paymentStatus == PaymentStatus.pending || 
                     e.paymentStatus == PaymentStatus.processing)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTodayEarnings() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _earningsBox.values
        .where((e) => e.earnedAt.isAfter(startOfDay) && e.earnedAt.isBefore(endOfDay))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getWeeklyEarnings() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _earningsBox.values
        .where((e) => e.earnedAt.isAfter(startOfWeekDay))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Offline queue operations
  static Future<void> addPendingAction(PendingAction action) async {
    await _offlineQueueBox.put(action.id, action);
  }

  static List<PendingAction> getPendingActions() {
    final actions = _offlineQueueBox.values.toList();
    actions.sort((a, b) {
      // Sort by priority first, then by creation time
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return actions;
  }

  static Future<void> removePendingAction(String actionId) async {
    await _offlineQueueBox.delete(actionId);
  }

  static Future<void> updatePendingAction(PendingAction action) async {
    await _offlineQueueBox.put(action.id, action);
  }

  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, [T? defaultValue]) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsBox.putAll(settings);
  }

  static Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_settingsBox.toMap());
  }

  // Auth tokens
  static Future<void> saveAuthToken(String token) async {
    await _settingsBox.put(AppConstants.authTokenKey, token);
  }

  static String? getAuthToken() {
    return _settingsBox.get(AppConstants.authTokenKey) as String?;
  }

  static Future<void> clearAuthToken() async {
    await _settingsBox.delete(AppConstants.authTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _settingsBox.put(AppConstants.userIdKey, userId);
  }

  static String? getUserId() {
    return _settingsBox.get(AppConstants.userIdKey) as String?;
  }

  // Utility methods
  static Future<void> clearAllData() async {
    await _riderBox.clear();
    await _campaignBox.clear();
    await _verificationBox.clear();
    await _locationBox.clear();
    await _earningsBox.clear();
    await _offlineQueueBox.clear();
    await _settingsBox.clear();
  }

  static Future<void> close() async {
    await _riderBox.close();
    await _campaignBox.close();
    await _verificationBox.close();
    await _locationBox.close();
    await _earningsBox.close();
    await _offlineQueueBox.close();
    await _settingsBox.close();
    _isInitialized = false;
  }

  // Statistics
  static Map<String, int> getStorageStats() {
    return {
      'riders': _riderBox.length,
      'campaigns': _campaignBox.length,
      'verifications': _verificationBox.length,
      'locations': _locationBox.length,
      'earnings': _earningsBox.length,
      'pendingActions': _offlineQueueBox.length,
      'settings': _settingsBox.length,
    };
  }

 // Enhanced Auth token methods for Kudisms integration
  static Future<void> saveRefreshToken(String token) async {
    await _settingsBox.put('refresh_token', token);
  }

  static String? getRefreshToken() {
    return _settingsBox.get('refresh_token') as String?;
  }

  static Future<void> clearRefreshToken() async {
    await _settingsBox.delete('refresh_token');
  }

  // Generic string storage methods for auth service compatibility
  static Future<void> setString(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  static Future<String?> getString(String key) async {
    return _settingsBox.get(key) as String?;
  }

  static Future<void> remove(String key) async {
    await _settingsBox.delete(key);
  }

  // Enhanced rider data methods
  static Future<void> saveRiderData(String riderJson) async {
    await _settingsBox.put(AppConstants.riderDataKey, riderJson);
  }

  static String? getRiderData() {
    return _settingsBox.get(AppConstants.riderDataKey) as String?;
  }

  static Future<void> clearRiderData() async {
    await _settingsBox.delete(AppConstants.riderDataKey);
  }

  // Complete auth cleanup method
  static Future<void> clearAuthData() async {
    await clearAuthToken();
    await clearRefreshToken();
    await clearRiderData();
    await clearRider();
  }

  // OTP rate limiting methods
  static Future<void> setOTPRateLimit(String phoneNumber) async {
    await _settingsBox.put('otp_rate_limit_$phoneNumber', DateTime.now().toIso8601String());
  }

  static bool isOTPRateLimited(String phoneNumber) {
    final lastSent = _settingsBox.get('otp_rate_limit_$phoneNumber') as String?;
    if (lastSent != null) {
      final lastSentTime = DateTime.parse(lastSent);
      final timeDiff = DateTime.now().difference(lastSentTime).inSeconds;
      return timeDiff < 60; // 1 minute rate limit
    }
    return false;
  }

  // Device ID storage methods
  static Future<void> saveDeviceId(String deviceId) async {
    await _settingsBox.put('device_id', deviceId);
  }

  static String? getDeviceId() {
    return _settingsBox.get('device_id') as String?;
  }

  static Future<void> clearDeviceId() async {
    await _settingsBox.delete('device_id');
  }

}