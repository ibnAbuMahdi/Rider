import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  // Support phone number (Nigerian format)
  static const String _supportPhoneNumber = '+2348012345678';
  
  // WhatsApp Business API endpoint
  static const String _whatsappBaseUrl = 'https://wa.me';

  // Launch WhatsApp chat with support
  static Future<bool> contactSupport({
    String? customMessage,
  }) async {
    final message = customMessage ?? _getDefaultSupportMessage();
    return await _launchWhatsApp(_supportPhoneNumber, message);
  }

  // Report an issue via WhatsApp
  static Future<bool> reportIssue({
    required String issueType,
    required String description,
    String? campaignId,
    String? earningId,
  }) async {
    final message = _getIssueReportMessage(
      issueType: issueType,
      description: description,
      campaignId: campaignId,
      earningId: earningId,
    );
    
    return await _launchWhatsApp(_supportPhoneNumber, message);
  }

  // Contact support for payment issues
  static Future<bool> contactPaymentSupport({
    required double amount,
    String? paymentReference,
  }) async {
    final message = _getPaymentSupportMessage(
      amount: amount,
      paymentReference: paymentReference,
    );
    
    return await _launchWhatsApp(_supportPhoneNumber, message);
  }

  // Share campaign with other riders
  static Future<bool> shareCampaign({
    required String campaignTitle,
    required double hourlyRate,
    required String campaignId,
    String? phoneNumber,
  }) async {
    final message = _getCampaignShareMessage(
      campaignTitle: campaignTitle,
      hourlyRate: hourlyRate,
      campaignId: campaignId,
    );
    
    if (phoneNumber != null) {
      return await _launchWhatsApp(phoneNumber, message);
    } else {
      // Share to any contact
      return await _shareMessage(message);
    }
  }

  // Send verification reminder to rider
  static Future<bool> sendVerificationReminder({
    required String campaignTitle,
    required int timeoutMinutes,
  }) async {
    final message = _getVerificationReminderMessage(
      campaignTitle: campaignTitle,
      timeoutMinutes: timeoutMinutes,
    );
    
    // This would typically be sent from the backend
    // For now, we can save it locally for support reference
    if (kDebugMode) {
      print('📱 Verification reminder: $message');
    }
    
    return true;
  }

  // Private method to launch WhatsApp
  static Future<bool> _launchWhatsApp(String phoneNumber, String message) async {
    try {
      // Remove any non-numeric characters from phone number
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Construct WhatsApp URL
      final whatsappUrl = '$_whatsappBaseUrl/$cleanPhoneNumber?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Could not launch WhatsApp URL: $whatsappUrl');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to launch WhatsApp: $e');
      }
      return false;
    }
  }

  // Private method to share message via system share
  static Future<bool> _shareMessage(String message) async {
    try {
      // This would use share_plus package
      // await Share.share(message);
      if (kDebugMode) {
        print('📤 Sharing message: $message');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to share message: $e');
      }
      return false;
    }
  }

  // Generate default support message
  static String _getDefaultSupportMessage() {
    return '''Hello Stika Support Team! 👋

I need assistance with the Stika Rider app.

Please help me with:
- [Describe your issue here]

Thank you!''';
  }

  // Generate issue report message
  static String _getIssueReportMessage({
    required String issueType,
    required String description,
    String? campaignId,
    String? earningId,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 Issue Report - Stika Rider App');
    buffer.writeln('');
    buffer.writeln('Issue Type: $issueType');
    buffer.writeln('Description: $description');
    
    if (campaignId != null) {
      buffer.writeln('Campaign ID: $campaignId');
    }
    
    if (earningId != null) {
      buffer.writeln('Earning ID: $earningId');
    }
    
    buffer.writeln('');
    buffer.writeln('Please investigate and resolve this issue.');
    buffer.writeln('');
    buffer.writeln('Time: ${DateTime.now().toString()}');
    
    return buffer.toString();
  }

  // Generate payment support message
  static String _getPaymentSupportMessage({
    required double amount,
    String? paymentReference,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('💰 Payment Support Request');
    buffer.writeln('');
    buffer.writeln('Amount: ₦${amount.toStringAsFixed(0)}');
    
    if (paymentReference != null) {
      buffer.writeln('Reference: $paymentReference');
    }
    
    buffer.writeln('');
    buffer.writeln('Issue: [Please describe your payment issue]');
    buffer.writeln('');
    buffer.writeln('Please help resolve my payment issue.');
    buffer.writeln('');
    buffer.writeln('Time: ${DateTime.now().toString()}');
    
    return buffer.toString();
  }

  // Generate campaign share message
  static String _getCampaignShareMessage({
    required String campaignTitle,
    required double hourlyRate,
    required String campaignId,
  }) {
    return '''🚀 Earn Money with Stika! 

Campaign: $campaignTitle
Rate: ₦${hourlyRate.toStringAsFixed(0)}/hour

Join this campaign and start earning by displaying ads on your tricycle!

Download Stika Rider app:
- Android: [Play Store Link]
- iOS: [App Store Link]

Campaign ID: $campaignId

#StikaEarnings #TricycleAds #NigeriaJobs''';
  }

  // Generate verification reminder message
  static String _getVerificationReminderMessage({
    required String campaignTitle,
    required int timeoutMinutes,
  }) {
    return '''⏰ Verification Reminder

Campaign: $campaignTitle
Time remaining: $timeoutMinutes minutes

Please take your verification photo now to continue earning.

Open the Stika Rider app and tap "Verify Now"''';
  }

  // Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final uri = Uri.parse('$_whatsappBaseUrl/');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  // Get support contact info
  static Map<String, String> getSupportContactInfo() {
    return {
      'phone': _supportPhoneNumber,
      'whatsapp': _supportPhoneNumber,
      'email': 'support@stika.ng',
      'website': 'https://stika.ng/support',
    };
  }
}