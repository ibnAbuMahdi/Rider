import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../core/models/location_record.dart';
import '../core/models/verification_request.dart';
import '../core/models/earning.dart';
import '../core/models/campaign.dart';
import '../models/sms_log.dart';
import '../core/services/api_service.dart';

class OfflineStorage {
  static final logger = Logger();
  
  static const BOXES = {
    'rider': 'rider_data',
    'earnings': 'earnings_history',
    'locations': 'location_cache',
    'verifications': 'verification_queue',
    'campaigns': 'campaign_data',
    'sms_logs': 'sms_logs',
    'offline_actions': 'offline_actions',
  };

  static Future<void> initialize() async {
    // Register Hive adapters
    Hive.registerAdapter(LocationRecordAdapter());
    Hive.registerAdapter(VerificationRequestAdapter());
    Hive.registerAdapter(EarningAdapter());
    Hive.registerAdapter(CampaignAdapter());
    Hive.registerAdapter(SMSLogAdapter());
    Hive.registerAdapter(OfflineActionAdapter());

    // Open all boxes
    for (final boxName in BOXES.values) {
      await Hive.openBox(boxName);
    }
  }

  static Future<bool> hasInternet() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  static Future<void> syncWithServer() async {
    if (!await hasInternet()) {
      logger.i('No internet connection, skipping sync');
      return;
    }
    
    logger.i('Starting sync with server...');
    
    try {
      // Priority sync order - most critical first
      await syncVerifications();  // Most critical
      await syncLocations();      // For earnings
      await syncEarnings();       // User wants to see
      await syncSMSLogs();        // For analytics
      await syncOfflineActions(); // Pending actions
      
      logger.i('Sync completed successfully');
    } catch (e) {
      logger.e('Sync failed: $e');
    }
  }

  static Future<void> syncVerifications() async {
    try {
      final box = await Hive.openBox<VerificationRequest>('verification_queue');
      final unsynced = box.values.where((v) => !v.synced).toList();
      
      logger.i('Syncing ${unsynced.length} verification requests');
      
      for (final verification in unsynced) {
        try {
          final result = await ApiService.submitVerification(verification);
          if (result['success'] == true) {
            verification.synced = true;
            await verification.save();
            logger.d('Verification ${verification.id} synced');
          }
        } catch (e) {
          logger.w('Failed to sync verification ${verification.id}: $e');
        }
      }
    } catch (e) {
      logger.e('Verification sync failed: $e');
    }
  }

  static Future<void> syncLocations() async {
    try {
      final box = await Hive.openBox<LocationRecord>('location_cache');
      final unsynced = box.values.where((l) => !l.synced).toList();
      
      logger.i('Syncing ${unsynced.length} location records');
      
      // Batch sync locations for efficiency
      const batchSize = 50;
      for (int i = 0; i < unsynced.length; i += batchSize) {
        final batch = unsynced.skip(i).take(batchSize).toList();
        
        try {
          final result = await ApiService.syncLocationBatch(batch);
          if (result['success'] == true) {
            for (final location in batch) {
              location.synced = true;
              await location.save();
            }
            logger.d('Synced batch of ${batch.length} locations');
          }
        } catch (e) {
          logger.w('Failed to sync location batch: $e');
        }
      }
    } catch (e) {
      logger.e('Location sync failed: $e');
    }
  }

  static Future<void> syncEarnings() async {
    try {
      final box = await Hive.openBox<Earning>('earnings_history');
      final unsynced = box.values.where((e) => !e.synced).toList();
      
      logger.i('Syncing ${unsynced.length} earnings records');
      
      for (final earning in unsynced) {
        try {
          final result = await ApiService.syncEarning(earning);
          if (result['success'] == true) {
            earning.synced = true;
            await earning.save();
            logger.d('Earning ${earning.id} synced');
          }
        } catch (e) {
          logger.w('Failed to sync earning ${earning.id}: $e');
        }
      }
    } catch (e) {
      logger.e('Earnings sync failed: $e');
    }
  }

  static Future<void> syncSMSLogs() async {
    try {
      final box = await Hive.openBox<SMSLog>('sms_logs');
      final unsynced = box.values.where((log) => !log.synced).toList();
      
      logger.i('Syncing ${unsynced.length} SMS logs');
      
      for (final log in unsynced) {
        try {
          final result = await ApiService.syncSMSLog(log);
          if (result['success'] == true) {
            log.synced = true;
            await log.save();
            logger.d('SMS log synced');
          }
        } catch (e) {
          logger.w('Failed to sync SMS log: $e');
        }
      }
    } catch (e) {
      logger.e('SMS log sync failed: $e');
    }
  }

  static Future<void> syncOfflineActions() async {
    try {
      final box = await Hive.openBox<OfflineAction>('offline_actions');
      final actions = box.values.toList();
      
      logger.i('Processing ${actions.length} offline actions');
      
      for (final action in actions) {
        try {
          await processOfflineAction(action);
          await box.delete(action.key);
          logger.d('Offline action ${action.type} processed');
        } catch (e) {
          logger.w('Failed to process offline action ${action.type}: $e');
        }
      }
    } catch (e) {
      logger.e('Offline action sync failed: $e');
    }
  }

  static Future<void> processOfflineAction(OfflineAction action) async {
    switch (action.type) {
      case 'verification':
        await ApiService.submitVerification(action.data);
        break;
      case 'location':
        await ApiService.syncLocationBatch([action.data]);
        break;
      case 'earnings':
        await ApiService.syncEarning(action.data);
        break;
      default:
        logger.w('Unknown offline action type: ${action.type}');
    }
  }

  static Future<void> addOfflineAction(String type, dynamic data) async {
    try {
      final box = await Hive.openBox<OfflineAction>('offline_actions');
      await box.add(OfflineAction(
        type: type,
        data: data,
        timestamp: DateTime.now(),
      ));
      logger.d('Offline action $type queued');
    } catch (e) {
      logger.e('Failed to add offline action: $e');
    }
  }

  static Future<void> clearOldData() async {
    try {
      // Clear old location records (keep last 1000)
      final locationBox = await Hive.openBox<LocationRecord>('location_cache');
      if (locationBox.length > 1000) {
        final keysToDelete = locationBox.keys.take(locationBox.length - 1000).toList();
        await locationBox.deleteAll(keysToDelete);
        logger.i('Cleared ${keysToDelete.length} old location records');
      }

      // Clear old SMS logs (keep last 30 days)
      final smsBox = await Hive.openBox<SMSLog>('sms_logs');
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final oldLogs = smsBox.values
          .where((log) => log.timestamp.isBefore(cutoffDate))
          .toList();
      
      for (final log in oldLogs) {
        await smsBox.delete(log.key);
      }
      logger.i('Cleared ${oldLogs.length} old SMS logs');

      // Clear synced verification requests (keep last 100)
      final verificationBox = await Hive.openBox<VerificationRequest>('verification_queue');
      final syncedVerifications = verificationBox.values
          .where((v) => v.synced)
          .toList();
      
      if (syncedVerifications.length > 100) {
        final toDelete = syncedVerifications.take(syncedVerifications.length - 100);
        for (final verification in toDelete) {
          await verificationBox.delete(verification.key);
        }
        logger.i('Cleared ${toDelete.length} old verification requests');
      }
    } catch (e) {
      logger.e('Failed to clear old data: $e');
    }
  }

  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = <String, dynamic>{};
      
      for (final entry in BOXES.entries) {
        final box = await Hive.openBox(entry.value);
        stats[entry.key] = {
          'count': box.length,
          'size': box.keys.length * 1024, // Approximate size in bytes
        };
      }
      
      return stats;
    } catch (e) {
      logger.e('Failed to get storage stats: $e');
      return {};
    }
  }
}

class OfflineAction extends HiveObject {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final DateTime timestamp;

  OfflineAction({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class OfflineActionAdapter extends TypeAdapter<OfflineAction> {
  @override
  final int typeId = 11;

  @override
  OfflineAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineAction(
      type: fields[0] as String,
      data: fields[1] as dynamic,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineAction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  bool get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}