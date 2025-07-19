import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/sms_log.dart';

class SMSService {
  static const String termiiBaseUrl = 'https://my.kudisms.net/api';
  static const String apiKey = 'sOWdHJYT6XAvCrRx0Fj1E8fizpBwPoGm3lt4hbSQnU7uNeIKaqLkg5DMV2yZ9c';
  static final dio = Dio();
  static final logger = Logger();

  static Future<bool> sendVerificationRequest(String phone, String riderId) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': 'URGENT: Snap your keke back now! You get 5 minutes. Open Stika app.',
          'type': 'plain',
          'channel': 'generic',
        },
      );

      // Log SMS for tracking
      await _logSMSEvent(phone, 'verification_request', riderId);

      return response.statusCode == 200;
    } catch (e) {
      logger.e('SMS sending failed: $e');
      return false;
    }
  }

  static Future<bool> sendPaymentNotification(String phone, double amount) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': 'Your money don reach! ₦${amount.toStringAsFixed(0)} for this week. Thank you! 💰',
          'type': 'plain',
          'channel': 'generic',
        },
      );

      await _logSMSEvent(phone, 'payment_notification', amount.toString());

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Payment SMS failed: $e');
      return false;
    }
  }

  static Future<bool> sendCampaignUpdate(String phone, String campaignName) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': 'New campaign: $campaignName. Open Stika app to see details.',
          'type': 'plain',
          'channel': 'generic',
        },
      );

      await _logSMSEvent(phone, 'campaign_update', campaignName);

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Campaign SMS failed: $e');
      return false;
    }
  }

  static Future<bool> sendOTP(String phone, String otp) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': 'Your Stika verification code is: $otp. Valid for 5 minutes.',
          'type': 'plain',
          'channel': 'generic',
        },
      );

      await _logSMSEvent(phone, 'otp_verification', otp);

      return response.statusCode == 200;
    } catch (e) {
      logger.e('OTP SMS failed: $e');
      return false;
    }
  }

  static Future<bool> sendVerificationSuccess(String phone, double earningsAdded) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': 'Good! Verification successful. You don earn ₦${earningsAdded.toStringAsFixed(0)} extra!',
          'type': 'plain',
          'channel': 'generic',
        },
      );

      await _logSMSEvent(phone, 'verification_success', earningsAdded.toString());

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Verification success SMS failed: $e');
      return false;
    }
  }

  static Future<bool> sendFallbackSMS(String phone, String message) async {
    try {
      final response = await dio.post(
        '$termiiBaseUrl/sms/send',
        data: {
          'api_key': apiKey,
          'to': formatNigerianNumber(phone),
          'from': 'Stika',
          'sms': message,
          'type': 'plain',
          'channel': 'generic',
        },
      );

      await _logSMSEvent(phone, 'fallback_sms', message);

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Fallback SMS failed: $e');
      return false;
    }
  }

  static String formatNigerianNumber(String phone) {
    // Remove any non-digits
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle different Nigerian number formats
    if (phone.startsWith('234')) {
      return phone;
    } else if (phone.startsWith('0')) {
      return '234${phone.substring(1)}';
    } else if (phone.length == 10) {
      return '234$phone';
    } else if (phone.startsWith('+234')) {
      return phone.substring(1);
    }
    
    return phone;
  }

  static Future<void> _logSMSEvent(String phone, String type, String data) async {
    try {
      final box = await Hive.openBox<SMSLog>('sms_logs');
      await box.add(SMSLog(
        phone: phone,
        type: type,
        data: data,
        timestamp: DateTime.now(),
        synced: false,
      ));
    } catch (e) {
      logger.w('Failed to log SMS event: $e');
    }
  }

  static Future<void> syncSMSLogs() async {
    try {
      final box = await Hive.openBox<SMSLog>('sms_logs');
      final unsynced = box.values.where((log) => !log.synced).toList();

      for (final log in unsynced) {
        // Send to backend for analytics
        try {
          await dio.post('/api/v1/sms-logs', data: log.toJson());
          log.synced = true;
          await log.save();
        } catch (e) {
          logger.w('Failed to sync SMS log: $e');
        }
      }
    } catch (e) {
      logger.e('SMS log sync failed: $e');
    }
  }
}
