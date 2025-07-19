class AppConstants {
  // App Information
  static const String appName = 'Stika Rider';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.stika.rider';
  
  // API Configuration
  static const String baseUrl = 'https://api.stika.ng';
  static const String apiVersion = 'v1';
  static const String apiTimeout = '30'; // seconds
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String riderDataKey = 'rider_data';
  static const String campaignDataKey = 'campaign_data';
  static const String locationDataKey = 'location_data';
  static const String earningsDataKey = 'earnings_data';
  static const String settingsKey = 'app_settings';
  
  // Hive Box Names
  static const String riderBox = 'rider_box';
  static const String campaignBox = 'campaign_box';
  static const String locationBox = 'location_box';
  static const String earningsBox = 'earnings_box';
  static const String verificationBox = 'verification_box';
  static const String offlineQueueBox = 'offline_queue_box';
  
  // Location Tracking
  static const int locationUpdateIntervalSeconds = 30;
  static const int stationaryIntervalMinutes = 5;
  static const double movementThresholdMeters = 10.0;
  static const int movementThresholdMetersInt = 10; // Integer version for distanceFilter
  static const int batteryLowThreshold = 20;
  static const int maxLocationCacheSize = 1000;
  
  // Verification
  static const int verificationTimeoutMinutes = 10;
  static const int maxVerificationRetries = 3;
  static const double verificationImageQuality = 0.8;
  static const int maxImageSizeKB = 500;
  
  // Payment
  static const String currency = 'NGN';
  static const String currencySymbol = '₦';
  static const int paymentDay = 5; // Friday (1 = Monday)
  
  // UI
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // Geofencing
  static const double defaultGeofenceRadius = 1000.0; // meters
  static const double geofenceAccuracy = 50.0; // meters
  
  // Background Tasks
  static const String locationTrackingTask = 'location_tracking_task';
  static const String syncDataTask = 'sync_data_task';
  
  // Notification Channels
  static const String defaultChannelId = 'stika_default_channel';
  static const String verificationChannelId = 'stika_verification_channel';
  static const String earningsChannelId = 'stika_earnings_channel';
  
  // WhatsApp Support
  static const String supportWhatsAppNumber = '+2348012345678';
  static const String supportBotNumber = '+2348087654321';
  
  // Error Messages
  static const String networkErrorMessage = 'No internet connection. Please check your network.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String locationErrorMessage = 'Cannot access location. Please enable GPS.';
  static const String cameraErrorMessage = 'Cannot access camera. Please check permissions.';
  static const String verificationErrorMessage = 'Verification failed. Please try again.';
  
  // Success Messages
  static const String verificationSuccessMessage = 'Verification successful!';
  static const String campaignJoinedMessage = 'Successfully joined campaign!';
  static const String paymentProcessedMessage = 'Payment processed successfully!';
  
  // Nigerian Specific
  static const String countryCode = 'NG';
  static const String phonePrefix = '+234';
  static const String defaultLanguage = 'en';
  static const String pidginLanguage = 'pcm'; // Pidgin English
  
  // Lagos coordinates (default center)
  static const double lagosLatitude = 6.5244;
  static const double lagosLongitude = 3.3792;
  
  // Anti-Gaming
  static const List<String> suspiciousApps = [
    'com.competitor.rider',
    'ng.blitz.driver',
    'com.uber.driver',
    'com.taxify.driver',
  ];
  
  // Rate Limits
  static const int maxAPICallsPerMinute = 60;
  static const int maxVerificationAttemptsPerHour = 10;
  static const int maxLocationUpdatesPerMinute = 4;
  
  // Debug
  static const bool enableDebugLogs = false;
  static const bool enablePerformanceLogging = true;

  // Api Keys
  static const String termiiApiKey = 'sOWdHJYT6XAvCrRx0Fj1E8fizpBwPoGm3lt4hbSQnU7uNeIKaqLkg5DMV2yZ9c';
  static const String googleMapsApiKey = 'AIzaSyDFFuBAimEje5haiQHWPZcmvwdzWUKhfkM';
}
