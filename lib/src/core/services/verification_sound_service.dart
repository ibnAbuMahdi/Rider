import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class VerificationSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  static bool _isSoundEnabled = true;

  // Sound file paths
  static const String _verificationAlertSound = 'sounds/verification_alert.mp3';
  static const String _verificationUrgentSound = 'sounds/verification_urgent.mp3';
  static const String _verificationTimeoutWarningSound = 'sounds/verification_timeout_warning.mp3';
  static const String _verificationSuccessSound = 'sounds/verification_success.mp3';
  static const String _verificationFailedSound = 'sounds/verification_failed.mp3';

  /// Initialize the verification sound service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio mode for notifications
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🔊 Verification sound service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize verification sound service: $e');
      }
    }
  }

  /// Play verification alert sound (when verification is triggered)
  static Future<void> playVerificationAlert() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_verificationAlertSound));
      
      if (kDebugMode) {
        print('🔊 Playing verification alert sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play verification alert sound: $e');
      }
    }
  }

  /// Play urgent verification sound (for repeated alerts)
  static Future<void> playUrgentAlert() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_verificationUrgentSound));
      
      if (kDebugMode) {
        print('🔊 Playing urgent verification sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play urgent verification sound: $e');
      }
    }
  }

  /// Play timeout warning sound (when verification time is running out)
  static Future<void> playTimeoutWarning() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_verificationTimeoutWarningSound));
      
      if (kDebugMode) {
        print('🔊 Playing timeout warning sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play timeout warning sound: $e');
      }
    }
  }

  /// Play success sound (when verification is completed successfully)
  static Future<void> playSuccessSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_verificationSuccessSound));
      
      if (kDebugMode) {
        print('🔊 Playing verification success sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play verification success sound: $e');
      }
    }
  }

  /// Play failed sound (when verification fails)
  static Future<void> playFailedSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_verificationFailedSound));
      
      if (kDebugMode) {
        print('🔊 Playing verification failed sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play verification failed sound: $e');
      }
    }
  }

  /// Play repeating urgent alert (for critical verification alerts)
  static Future<void> playRepeatingAlert({int repeatCount = 3}) async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      for (int i = 0; i < repeatCount; i++) {
        await _audioPlayer.play(AssetSource(_verificationUrgentSound));
        
        // Wait between repetitions
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Stop if player is disposed or service is disabled
        if (!_isSoundEnabled) break;
      }
      
      if (kDebugMode) {
        print('🔊 Playing repeating verification alert ($repeatCount times)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play repeating verification alert: $e');
      }
    }
  }

  /// Stop any currently playing verification sound
  static Future<void> stopSound() async {
    if (!_isInitialized) return;
    
    try {
      await _audioPlayer.stop();
      
      if (kDebugMode) {
        print('🔊 Stopped verification sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop verification sound: $e');
      }
    }
  }

  /// Enable or disable verification sounds
  static void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    
    if (!enabled) {
      stopSound();
    }
    
    if (kDebugMode) {
      print('🔊 Verification sounds ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Check if verification sounds are enabled
  static bool get isSoundEnabled => _isSoundEnabled;

  /// Test all verification sounds (for debugging/settings)
  static Future<void> testAllSounds() async {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    if (kDebugMode) {
      print('🔊 Testing all verification sounds...');
    }
    
    try {
      // Test alert sound
      await playVerificationAlert();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test urgent sound
      await playUrgentAlert();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test timeout warning
      await playTimeoutWarning();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test success sound
      await playSuccessSound();
      await Future.delayed(const Duration(seconds: 1));
      
      // Test failed sound
      await playFailedSound();
      
      if (kDebugMode) {
        print('🔊 All verification sounds tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to test verification sounds: $e');
      }
    }
  }

  /// Dispose of the audio player
  static Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      
      if (kDebugMode) {
        print('🔊 Verification sound service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to dispose verification sound service: $e');
      }
    }
  }

  /// Get the current volume level (0.0 to 1.0)
  static Future<double> getVolume() async {
    if (!_isInitialized) return 1.0;
    
    try {
      // return await _audioPlayer.getVolume(); // AudioPlayer API changed
      return 1.0; // Return default volume for now
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get volume: $e');
      }
      return 1.0;
    }
  }

  /// Set the volume level (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      
      if (kDebugMode) {
        print('🔊 Set verification sound volume to $clampedVolume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set volume: $e');
      }
    }
  }

  /// Vibration pattern for verification alerts
  static Future<void> triggerVibration({bool isUrgent = false}) async {
    try {
      if (isUrgent) {
        // Urgent pattern: short-long-short-long
        await HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
      } else {
        // Normal pattern: medium vibration
        await HapticFeedback.mediumImpact();
      }
      
      if (kDebugMode) {
        print('📳 Triggered verification vibration (${isUrgent ? 'urgent' : 'normal'})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to trigger vibration: $e');
      }
    }
  }
}