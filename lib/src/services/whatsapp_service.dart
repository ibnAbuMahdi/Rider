import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import '../services/sms_service.dart';
import '../core/models/rider.dart';

class WhatsAppService {
  static final logger = Logger();
  static const String supportNumber = '+2348012345678';
  static const String botNumber = '+2348087654321';

  static Future<void> openSupportChat([String? customMessage]) async {
    try {
      final rider = await _getCurrentRider();
      final message = customMessage ?? 
          'Hello, I need help with my Stika account. '
          'My number is ${rider?.phone ?? 'Not available'}';
      
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'whatsapp://send?phone=$supportNumber&text=$encodedMessage';
      
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
        logger.i('WhatsApp support chat opened');
      } else {
        // Fallback to SMS
        await _fallbackToSMS(supportNumber, message);
      }
    } catch (e) {
      logger.e('Failed to open WhatsApp support: $e');
      await _fallbackToSMS(supportNumber, 'Help request from Stika rider');
    }
  }

  static Future<void> shareEarnings() async {
    try {
      final rider = await _getCurrentRider();
      if (rider == null) return;
      
      final weeklyEarnings = await _getWeeklyEarnings();
      
      final message = 'I don make ₦${weeklyEarnings.toStringAsFixed(0)} this week with Stika! '
          'Join with my code ${rider.referralCode} '
          'and start earning too! 💰\n\n'
          'Download: https://bit.ly/stika-rider';
      
      await Share.share(message);
      logger.i('Earnings shared successfully');
    } catch (e) {
      logger.e('Failed to share earnings: $e');
    }
  }

  static Future<void> shareReferralCode() async {
    try {
      final rider = await _getCurrentRider();
      if (rider == null) return;
      
      final message = 'Join me on Stika and earn extra money with your keke! '
          'Use my code ${rider.referralCode} when you sign up.\n\n'
          'Download: https://bit.ly/stika-rider';
      
      await Share.share(message);
      logger.i('Referral code shared successfully');
    } catch (e) {
      logger.e('Failed to share referral: $e');
    }
  }

  static Future<void> reportIssue(String issueType, String description) async {
    try {
      final rider = await _getCurrentRider();
      final message = 'ISSUE REPORT\n\n'
          'Type: $issueType\n'
          'Description: $description\n\n'
          'Rider: ${rider?.phone ?? 'Unknown'}\n'
          'Time: ${DateTime.now().toString()}';
      
      await openSupportChat(message);
    } catch (e) {
      logger.e('Failed to report issue: $e');
    }
  }

  static Future<void> requestVerificationHelp() async {
    try {
      final message = 'I need help with verification. '
          'My camera is not working properly or I don\'t understand the process.';
      
      await openSupportChat(message);
    } catch (e) {
      logger.e('Failed to request verification help: $e');
    }
  }

  static Future<void> requestPaymentHelp() async {
    try {
      final message = 'I have a question about my payments. '
          'Please help me understand when I will receive my money.';
      
      await openSupportChat(message);
    } catch (e) {
      logger.e('Failed to request payment help: $e');
    }
  }

  static Future<void> sendWhatsAppBusinessMessage(String phone, String message) async {
    try {
      // This would use Termii's WhatsApp Business API
      // For now, we'll use regular WhatsApp
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'whatsapp://send?phone=$phone&text=$encodedMessage';
      
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
        logger.i('WhatsApp business message sent');
      } else {
        // Fallback to SMS
        await SMSService.sendFallbackSMS(phone, message);
      }
    } catch (e) {
      logger.e('WhatsApp business message failed: $e');
      // Fallback to SMS
      await SMSService.sendFallbackSMS(phone, message);
    }
  }

  static Future<void> joinRiderCommunity() async {
    try {
      const communityUrl = 'https://chat.whatsapp.com/XXXXXX'; // Stika riders group
      
      if (await canLaunch(communityUrl)) {
        await launch(communityUrl);
        logger.i('Joined rider community');
      } else {
        await openSupportChat('I want to join the Stika riders WhatsApp group');
      }
    } catch (e) {
      logger.e('Failed to join community: $e');
    }
  }

  static Future<void> shareSuccessStory(String story) async {
    try {
      final message = 'SUCCESS STORY 🎉\n\n'
          '$story\n\n'
          'I\'m earning with Stika! Join me and start earning too.\n'
          'Download: https://bit.ly/stika-rider';
      
      await Share.share(message);
      logger.i('Success story shared');
    } catch (e) {
      logger.e('Failed to share success story: $e');
    }
  }

  static Future<void> _fallbackToSMS(String phone, String message) async {
    try {
      final smsUrl = 'sms:$phone?body=${Uri.encodeComponent(message)}';
      
      if (await canLaunch(smsUrl)) {
        await launch(smsUrl);
        logger.i('Fallback SMS opened');
      } else {
        logger.w('Neither WhatsApp nor SMS launcher available');
      }
    } catch (e) {
      logger.e('SMS fallback failed: $e');
    }
  }

  static Future<Rider?> _getCurrentRider() async {
    // This would get the current rider from local storage
    // For now, return null
    return null;
  }

  static Future<double> _getWeeklyEarnings() async {
    // This would get weekly earnings from local storage
    // For now, return 0
    return 0.0;
  }

  // Quick action methods for common support scenarios
  static Future<void> quickHelp(String scenario) async {
    switch (scenario) {
      case 'verification':
        await requestVerificationHelp();
        break;
      case 'payment':
        await requestPaymentHelp();
        break;
      case 'campaign':
        await openSupportChat('I have questions about my current campaign');
        break;
      case 'app_issue':
        await openSupportChat('The app is not working properly');
        break;
      case 'account':
        await openSupportChat('I have questions about my account');
        break;
      default:
        await openSupportChat();
    }
  }
}