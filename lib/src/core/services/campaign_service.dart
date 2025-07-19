import '../models/campaign.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class CampaignResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  const CampaignResult({
    required this.success,
    this.error,
    this.data,
  });
}

class CampaignService {
  final ApiService _apiService = ApiService();

  Future<List<Campaign>> getAvailableCampaigns() async {
    try {
      final response = await _apiService.get('/campaigns/available/');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data['results'] ?? response.data;
        return campaignsJson
            .map((json) => Campaign.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load campaigns');
      }
    } catch (e) {
      throw Exception('Failed to fetch campaigns: $e');
    }
  }

  Future<Campaign> getCampaignDetails(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/');
      
      if (response.statusCode == 200) {
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Campaign not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch campaign details: $e');
    }
  }

  Future<CampaignResult> joinCampaign(String campaignId) async {
    try {
      final response = await _apiService.post('/campaigns/$campaignId/join/', data: {});
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        return CampaignResult(
          success: false,
          error: errorData['message'] ?? errorData['error'] ?? 'Failed to join campaign',
        );
      }
    } catch (e) {
      return CampaignResult(
        success: false,
        error: 'Failed to join campaign: $e',
      );
    }
  }

  Future<CampaignResult> leaveCampaign(String campaignId) async {
    try {
      final response = await _apiService.post('/campaigns/$campaignId/leave/', data: {});
      
      if (response.statusCode == 200) {
        return CampaignResult(
          success: true,
          data: response.data,
        );
      } else {
        final errorData = response.data;
        return CampaignResult(
          success: false,
          error: errorData['message'] ?? errorData['error'] ?? 'Failed to leave campaign',
        );
      }
    } catch (e) {
      return CampaignResult(
        success: false,
        error: 'Failed to leave campaign: $e',
      );
    }
  }

  Future<List<Campaign>> getMyCampaigns() async {
    try {
      final response = await _apiService.get('/campaigns/my-campaigns/');
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data['results'] ?? response.data;
        return campaignsJson
            .map((json) => Campaign.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load my campaigns');
      }
    } catch (e) {
      throw Exception('Failed to fetch my campaigns: $e');
    }
  }

  Future<Campaign?> getCurrentCampaign() async {
    try {
      final response = await _apiService.get('/campaigns/current/');
      
      if (response.statusCode == 200 && response.data != null) {
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      } else {
        return null; // No current campaign
      }
    } catch (e) {
      return null; // No current campaign or error
    }
  }

  Future<Map<String, dynamic>> getCampaignStats(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/stats/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load campaign stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch campaign stats: $e');
    }
  }

  Future<List<Campaign>> searchCampaigns({
    String? query,
    String? area,
    double? minRate,
    double? maxRate,
    String? campaignType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (minRate != null) {
        queryParams['min_rate'] = minRate.toString();
      }
      if (maxRate != null) {
        queryParams['max_rate'] = maxRate.toString();
      }
      if (campaignType != null && campaignType.isNotEmpty) {
        queryParams['campaign_type'] = campaignType;
      }

      final response = await _apiService.get(
        '/campaigns/search/',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> campaignsJson = response.data['results'] ?? response.data;
        return campaignsJson
            .map((json) => Campaign.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search campaigns');
      }
    } catch (e) {
      throw Exception('Failed to search campaigns: $e');
    }
  }

  // Check if rider meets campaign requirements
  Future<Map<String, dynamic>> checkEligibility(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/check-eligibility/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to check eligibility');
      }
    } catch (e) {
      throw Exception('Failed to check eligibility: $e');
    }
  }

  // Get campaign performance for rider
  Future<Map<String, dynamic>> getCampaignPerformance(String campaignId) async {
    try {
      final response = await _apiService.get('/campaigns/$campaignId/my-performance/');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load performance data');
      }
    } catch (e) {
      throw Exception('Failed to fetch performance data: $e');
    }
  }
}