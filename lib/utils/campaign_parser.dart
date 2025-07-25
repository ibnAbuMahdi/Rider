import '../src/core/models/campaign.dart'; // Assuming your campaign.dart is in this path
import 'package:json_annotation/json_annotation.dart';
// ... (other imports)

// Example of a manual parsing function for Campaign
Campaign parseCampaignManually(Map<String, dynamic> json) {
  print('--- Manual Parsing Campaign ---');
  print('Raw JSON for Campaign: $json');

  // Helper function to safely get a string, or null if not found/invalid
  String? safeGetString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is String) {
      return value;
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected String)');
    return value.toString(); // Attempt to convert if possible, or handle error
  }

  // Helper for int
  int? safeGetInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is String) { // Handle string numbers like "8" for max_riders
      try {
        return int.parse(value);
      } catch (e) {
        print('DEBUG: Could not parse "$key" ($value) as int from String: $e');
        return null;
      }
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected int)');
    return null;
  }

  // Helper for double
  double? safeGetDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is int) return value.toDouble(); // int can be safely converted to double
    if (value is double) return value;
    if (value is String) { // Handle string numbers like "8000.00" for fixed_daily_rate
      try {
        return double.parse(value);
      } catch (e) {
        print('DEBUG: Could not parse "$key" ($value) as double from String: $e');
        return null;
      }
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected double)');
    return null;
  }

  // Helper for List<String>
  List<String>? safeGetStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is List) {
      return value.map((e) {
        if (e is String) return e;
        print('DEBUG: List "$key" contains non-string element: $e (Type: ${e.runtimeType})');
        return e.toString(); // Attempt to convert non-strings
      }).toList();
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected List)');
    return null;
  }

  // Helper for DateTime
  DateTime? safeGetDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('DEBUG: Could not parse "$key" ($value) as DateTime: $e');
        return null;
      }
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected String for DateTime)');
    return null;
  }

  // Helper for nested objects like Geofence
  List<Geofence>? safeGetGeofences(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is List) {
      return value.map((e) {
        if (e is Map<String, dynamic>) {
          // You'd need a similar manual parsing function for Geofence
          // For simplicity here, we'll assume Geofence.fromJson works or you manually parse it too.
          return Geofence.fromJson(e); // Or call parseGeofenceManually(e)
        }
        print('DEBUG: Geofence list "$key" contains non-map element: $e (Type: ${e.runtimeType})');
        return null; // Or throw error, depending on desired strictness
      }).whereType<Geofence>().toList(); // Filter out nulls if any were created
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected List for Geofences)');
    return null;
  }

  // Helper for nested objects like CampaignRequirements
  CampaignRequirements? safeGetRequirements(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      print('DEBUG: Field "$key" is NULL');
      return null;
    }
    if (value is Map<String, dynamic>) {
      // Assuming CampaignRequirements.fromJson works
      return CampaignRequirements.fromJson(value); // Or call parseRequirementsManually(value)
    }
    print('DEBUG: Field "$key" has unexpected type: ${value.runtimeType} (Expected Map for Requirements)');
    return null;
  }

  try {
    return Campaign(
      id: safeGetString(json, 'id'), // Allow null ID
      name: safeGetString(json, 'name'), // Allow null name
      description: safeGetString(json, 'description'),
      clientName: safeGetString(json, 'client_name'),
      agencyId: safeGetString(json, 'agency_id'), // Allow null agency ID
      agencyName: safeGetString(json, 'agency_name'),
      stickerImageUrl: safeGetString(json, 'sticker_image_url'), // Allow null sticker image URL
      ratePerKm: safeGetDouble(json, 'rate_per_km'),
      ratePerHour: safeGetDouble(json, 'rate_per_hour'),
      fixedDailyRate: safeGetDouble(json, 'fixed_daily_rate'), // Backend sends "8000.00" as string, parse as double
      startDate: safeGetDateTime(json, 'start_date') ?? DateTime.now(), // Default to current date if null
      endDate: safeGetDateTime(json, 'end_date') ?? DateTime.now().add(Duration(days: 30)), // Default to 30 days from now if null
      status: CampaignStatus.values.firstWhere(
        (e) => e.toString().split('.').last == safeGetString(json, 'status'),
        orElse: () {
          print('DEBUG: Unknown status: ${safeGetString(json, 'status')}, defaulting to draft');
          return CampaignStatus.draft;
        },
      ),
      geofences: safeGetGeofences(json, 'geofences') ?? [],
      maxRiders: safeGetInt(json, 'max_riders'), // Backend sends "8" as string, parse as int
      currentRiders: safeGetInt(json, 'current_riders'),
      requirements: safeGetRequirements(json, 'requirements') ?? const CampaignRequirements(), // Default empty requirements if null
      estimatedWeeklyEarnings: safeGetDouble(json, 'estimated_weekly_earnings'),
      area: safeGetString(json, 'area'),
      targetAudiences: safeGetStringList(json, 'target_audiences') ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?, // Directly cast Map, it's nullable
      createdAt: safeGetDateTime(json, 'created_at') ?? DateTime.now(), // Default to current date if null
      updatedAt: safeGetDateTime(json, 'updated_at'),
      isActive: json['is_active'] as bool? ?? false, // Check type and provide default
      totalVerifications: safeGetInt(json, 'total_verifications'),
      totalDistanceCovered: safeGetDouble(json, 'total_distance_covered'),
      budget: safeGetDouble(json, 'budget'), // Backend sends "80000.00" as string, parse as double
      spent: safeGetDouble(json, 'spent'), // Backend sends "0.00" as string, parse as double
    );
  } catch (e) {
    print('CRITICAL ERROR DURING MANUAL PARSING: $e');
    rethrow; // Rethrow to see the full stack trace
  }
}