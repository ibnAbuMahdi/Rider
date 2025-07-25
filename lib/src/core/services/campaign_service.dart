import '../models/campaign.dart';
import 'api_service.dart';
import '../../../utils/campaign_parser.dart';

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
        final responseData = response.data;
        print('🎯 CAMPAIGN API SUCCESS: Received real data from server');
        print('🎯 Response type: ${responseData.runtimeType}');
        
        // Handle both array and object responses
        List<dynamic> campaignsJson;
        if (responseData is Map<String, dynamic>) {
          campaignsJson = responseData['results'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          campaignsJson = responseData;
        } else {
          print('🎯 WARNING: Unexpected response format, using mock data');
          return _getMockCampaigns();
        }
        
        print('🎯 CAMPAIGNS JSON: Found ${campaignsJson.length} campaigns');
        
        // Parse campaigns with error handling
        final campaigns = <Campaign>[];
        for (int i = 0; i < campaignsJson.length; i++) {
          try {
            final campaignJson = campaignsJson[i];
            if (campaignJson is Map<String, dynamic>) {
              campaigns.add(Campaign.fromJson(campaignJson));
              //campaigns.add(parseCampaignManually(campaignJson));
		print('🎯 PARSED CAMPAIGN ${i + 1}: ${campaignJson['name'] ?? 'Unknown'}');
            } else {
              print('🎯 WARNING: Campaign $i is not a Map, skipping');
            }
          } catch (e) {
            print('🎯 ERROR parsing campaign $i: $e');
            // Continue with other campaigns instead of failing completely
          }
        }
        
        if (campaigns.isNotEmpty) {
          print('🎯 CAMPAIGN SERVICE SUCCESS: Returning ${campaigns.length} real campaigns');
          return campaigns;
        } else {
          print('🎯 WARNING: No valid campaigns parsed, using mock data');
          return _getMockCampaigns();
        }
      } else {
        print('🎯 CAMPAIGN API ERROR: Status ${response.statusCode}, using mock data');
        return _getMockCampaigns();
      }
    } catch (e) {
      print('🎯 CAMPAIGN API EXCEPTION: $e, using mock data as fallback');
      print('🎯 Exception type: ${e.runtimeType}');
      return _getMockCampaigns();
    }
  }

  List<Campaign> _getMockCampaigns() {
    print('🎭 USING MOCK DATA: Returning 4 mock campaigns');
    return [
      Campaign(
        id: 'camp_001',
        name: 'Coca-Cola Lagos Campaign',
        description: 'Promote Coca-Cola across Lagos mainland and island areas',
        clientName: 'Coca-Cola Nigeria',
        agencyId: 'agency_001',
        agencyName: 'Publicis Lagos',
        stickerImageUrl: 'https://via.placeholder.com/400x200/ff0000/ffffff?text=Coca-Cola',
        ratePerKm: 25.0,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: CampaignStatus.running,
        maxRiders: 200,
        currentRiders: 150,
        requirements: const CampaignRequirements(
          minRating: 4,
          minCompletedCampaigns: 2,
          requiresVerification: true,
        ),
        estimatedWeeklyEarnings: 15000.0,
        area: 'Lagos Island & Mainland',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
        budget: 5000000.0,
        spent: 2500000.0,
      ),
      Campaign(
        id: 'camp_002', 
        name: 'MTN Data Campaign',
        description: 'Advertise MTN data packages in high-traffic areas',
        clientName: 'MTN Nigeria',
        agencyId: 'agency_002',
        agencyName: 'Noah\'s Ark Lagos',
        stickerImageUrl: 'https://via.placeholder.com/400x200/ffcc00/000000?text=MTN',
        ratePerKm: 30.0,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        status: CampaignStatus.running,
        maxRiders: 150,
        currentRiders: 95,
        requirements: const CampaignRequirements(
          minRating: 3,
          minCompletedCampaigns: 1,
          requiresVerification: true,
        ),
        estimatedWeeklyEarnings: 18000.0,
        area: 'Victoria Island, Ikoyi, Lekki',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isActive: true,
        budget: 3500000.0,
        spent: 875000.0,
      ),
      Campaign(
        id: 'camp_003',
        name: 'Dangote Cement Promo',
        description: 'Building materials awareness campaign',
        clientName: 'Dangote Cement',
        agencyId: 'agency_003',
        agencyName: 'X3M Ideas',
        stickerImageUrl: 'https://via.placeholder.com/400x200/0066cc/ffffff?text=Dangote',
        ratePerKm: 20.0,
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 60)),
        status: CampaignStatus.pending,
        maxRiders: 100,
        currentRiders: 0,
        requirements: const CampaignRequirements(
          minRating: 4,
          minCompletedCampaigns: 3,
          requiresVerification: true,
        ),
        estimatedWeeklyEarnings: 12000.0,
        area: 'Ikeja, Surulere, Yaba',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isActive: false,
        budget: 2000000.0,
        spent: 0.0,
      ),
      Campaign(
        id: 'camp_004',
        name: 'Zenith Bank Digital',
        description: 'Promote Zenith Bank mobile banking app',
        clientName: 'Zenith Bank',
        agencyId: 'agency_004', 
        agencyName: 'Insight Communications',
        stickerImageUrl: 'https://via.placeholder.com/400x200/8b0000/ffffff?text=Zenith+Bank',
        ratePerKm: 35.0,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 21)),
        status: CampaignStatus.running,
        maxRiders: 75,
        currentRiders: 75,
        requirements: const CampaignRequirements(
          minRating: 5,
          minCompletedCampaigns: 5,
          requiresVerification: true,
        ),
        estimatedWeeklyEarnings: 21000.0,
        area: 'Marina, CMS, Broad Street',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
        budget: 1500000.0,
        spent: 300000.0,
      ),
    ];
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