import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../core/models/campaign.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../shared/widgets/loading_button.dart';
import '../widgets/geofence_info_card.dart';

class CampaignDetailsScreen extends ConsumerStatefulWidget {
  final Campaign campaign;

  const CampaignDetailsScreen({
    super.key,
    required this.campaign,
  });

  @override
  ConsumerState<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends ConsumerState<CampaignDetailsScreen> {
  GoogleMapController? _mapController;
  Geofence? _selectedGeofence;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polygon> _polygons = {};
  bool _isMapReady = false;
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🗺️ CAMPAIGN DETAILS: Initializing screen for campaign ${widget.campaign.id}');
      print('🗺️ Campaign has ${widget.campaign.geofences.length} geofences');
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMapData();
    });
  }

  void _initializeMapData() {
    if (kDebugMode) {
      print('🗺️ CAMPAIGN DETAILS: Initializing map data');
    }
    
    _createMapElements();
    
    if (widget.campaign.geofences.isNotEmpty) {
      _selectedGeofence = widget.campaign.geofences.first;
      if (kDebugMode) {
        print('🗺️ Selected default geofence: ${_selectedGeofence?.name}');
      }
    }
    
    setState(() {});
  }

  void _createMapElements() {
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};
    final Set<Polygon> polygons = {};

    for (int i = 0; i < widget.campaign.geofences.length; i++) {
      final geofence = widget.campaign.geofences[i];
      
      if (kDebugMode) {
        print('🗺️ Creating map element for geofence ${geofence.name} (${geofence.shape})');
      }

      // Create marker for geofence center
      markers.add(
        Marker(
          markerId: MarkerId('geofence_${geofence.id}'),
          position: LatLng(geofence.centerLatitude, geofence.centerLongitude),
          infoWindow: InfoWindow(
            title: geofence.name ?? 'Geofence ${i + 1}',
            snippet: _getGeofenceSnippet(geofence),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            geofence.canAcceptRiders ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          onTap: () => _selectGeofence(geofence),
        ),
      );

      // Create circle or polygon based on shape
      if (geofence.shape == GeofenceShape.circle && geofence.radius != null) {
        circles.add(
          Circle(
            circleId: CircleId('circle_${geofence.id}'),
            center: LatLng(geofence.centerLatitude, geofence.centerLongitude),
            radius: geofence.radius!,
            fillColor: Color(geofence.displayColor).withOpacity(0.2 * geofence.displayAlpha),
            strokeColor: Color(geofence.displayColor).withOpacity(geofence.displayAlpha),
            strokeWidth: geofence.isHighPriority ? 3 : 2,
            consumeTapEvents: true,
            onTap: () => _selectGeofence(geofence),
          ),
        );
      } else if (geofence.shape == GeofenceShape.polygon && 
                 geofence.polygonPoints != null && 
                 geofence.polygonPoints!.isNotEmpty) {
        polygons.add(
          Polygon(
            polygonId: PolygonId('polygon_${geofence.id}'),
            points: geofence.polygonPoints!
                .map((point) => LatLng(point.latitude ?? 0.0, point.longitude ?? 0.0))
                .toList(),
            fillColor: Color(geofence.displayColor).withOpacity(0.2 * geofence.displayAlpha),
            strokeColor: Color(geofence.displayColor).withOpacity(geofence.displayAlpha),
            strokeWidth: geofence.isHighPriority ? 3 : 2,
            consumeTapEvents: true,
            onTap: () => _selectGeofence(geofence),
          ),
        );
      }
    }

    _markers = markers;
    _circles = circles;
    _polygons = polygons;
  }

  String _getGeofenceSnippet(Geofence geofence) {
    final rate = geofence.rateType == 'per_km' 
        ? '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km'
        : '${AppConstants.currencySymbol}${(geofence.ratePerHour ?? 0).toStringAsFixed(0)}/hr';
    final slots = '${geofence.availableSlots ?? 0} slots available';
    return '$rate • $slots';
  }

  void _selectGeofence(Geofence geofence) {
    if (kDebugMode) {
      print('🗺️ GEOFENCE SELECTED: ${geofence.name}');
      print('🗺️ Can accept riders: ${geofence.canAcceptRiders}');
      print('🗺️ Available slots: ${geofence.availableSlots}');
    }

    setState(() {
      _selectedGeofence = geofence;
    });

    // Move camera to selected geofence
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(geofence.centerLatitude, geofence.centerLongitude),
        15.0,
      ),
    );
  }

  CameraPosition _getInitialCameraPosition() {
    if (widget.campaign.geofences.isEmpty) {
      // Default to Lagos, Nigeria if no geofences
      return const CameraPosition(
        target: LatLng(6.5244, 3.3792),
        zoom: 10.0,
      );
    }

    // Calculate bounds for all geofences
    double minLat = widget.campaign.geofences.first.centerLatitude;
    double maxLat = widget.campaign.geofences.first.centerLatitude;
    double minLng = widget.campaign.geofences.first.centerLongitude;
    double maxLng = widget.campaign.geofences.first.centerLongitude;

    for (final geofence in widget.campaign.geofences) {
      minLat = math.min(minLat, geofence.centerLatitude);
      maxLat = math.max(maxLat, geofence.centerLatitude);
      minLng = math.min(minLng, geofence.centerLongitude);
      maxLng = math.max(maxLng, geofence.centerLongitude);
    }

    // Center camera on all geofences
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 12.0,
    );
  }

  void _fitCameraToBounds() {
    if (_mapController == null || widget.campaign.geofences.isEmpty) return;

    double minLat = widget.campaign.geofences.first.centerLatitude;
    double maxLat = widget.campaign.geofences.first.centerLatitude;
    double minLng = widget.campaign.geofences.first.centerLongitude;
    double maxLng = widget.campaign.geofences.first.centerLongitude;

    for (final geofence in widget.campaign.geofences) {
      // Account for radius when calculating bounds
      final radiusOffset = (geofence.radius ?? 1000) / 111320; // Convert meters to degrees
      
      minLat = math.min(minLat, geofence.centerLatitude - radiusOffset);
      maxLat = math.max(maxLat, geofence.centerLatitude + radiusOffset);
      minLng = math.min(minLng, geofence.centerLongitude - radiusOffset);
      maxLng = math.max(maxLng, geofence.centerLongitude + radiusOffset);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign.name ?? 'Campaign Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitCameraToBounds,
            tooltip: 'Fit to screen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Campaign Header
          _buildCampaignHeader(),
          
          // Map and geofence selection
          Expanded(
            child: Column(
              children: [
                // Map
                Expanded(
                  flex: 3,
                  child: _buildMap(),
                ),
                
                // Selected geofence details
                if (_selectedGeofence != null)
                  Flexible(
                    flex: 2,
                    child: _buildGeofenceDetails(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.campaign.name ?? 'Unnamed Campaign',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.campaign.clientName != null)
                      Text(
                        'by ${widget.campaign.clientName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.campaign.status == CampaignStatus.running
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.campaign.status.displayName,
                  style: TextStyle(
                    color: widget.campaign.status == CampaignStatus.running
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetric(
                icon: Icons.location_on,
                label: 'Geofences',
                value: '${widget.campaign.geofences.length}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                icon: Icons.people,
                label: 'Total Slots',
                value: '${widget.campaign.geofences.fold(0, (sum, g) => sum + (g.maxRiders ?? 0))}',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                icon: Icons.attach_money,
                label: 'Base Rate',
                value: '${AppConstants.currencySymbol}${(widget.campaign.ratePerKm ?? 0).toStringAsFixed(0)}/km',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: GoogleMap(
        initialCameraPosition: _getInitialCameraPosition(),
        onMapCreated: (GoogleMapController controller) {
          if (kDebugMode) {
            print('🗺️ GOOGLE MAP: Map controller created');
          }
          _mapController = controller;
          _isMapReady = true;
          
          // Fit camera to bounds after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _fitCameraToBounds();
          });
        },
        markers: _markers,
        circles: _circles,
        polygons: _polygons,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        buildingsEnabled: true,
        trafficEnabled: false,
      ),
    );
  }

  Widget _buildGeofenceDetails() {
    if (_selectedGeofence == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'Tap on a geofence marker to view details',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400, // Limit maximum height to prevent overflow
      ),
      child: GeofenceInfoCard(
        geofence: _selectedGeofence!,
        onJoinGeofence: _selectedGeofence!.canAcceptRiders
            ? () => _showJoinGeofenceDialog(_selectedGeofence!)
            : null,
      ),
    );
  }

  void _showJoinGeofenceDialog(Geofence geofence) {
    if (kDebugMode) {
      print('🎯 GEOFENCE JOIN: Showing verification dialog for ${geofence.name}');
    }

    // Clear any previous errors when opening the dialog
    ref.read(campaignProvider.notifier).clearError();

    showDialog(
      context: context,
      builder: (context) => _VerificationJoinDialog(geofence: geofence),
    );
  }

  Widget _buildGeofenceJoinInfo(Geofence geofence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Rate',
          _getGeofenceRateDisplay(geofence),
          AppColors.success,
        ),
        _buildInfoRow(
          'Available Slots',
          '${geofence.availableSlots ?? 0} of ${geofence.maxRiders ?? 0}',
          AppColors.primary,
        ),
        _buildInfoRow(
          'Estimated Daily Earnings',
          '${AppConstants.currencySymbol}${geofence.estimatedDailyEarnings.toStringAsFixed(0)}',
          AppColors.earnings,
        ),
        if (geofence.specialInstructions?.isNotEmpty ?? false)
          _buildInfoRow(
            'Special Instructions',
            geofence.specialInstructions!,
            AppColors.textSecondary,
          ),
      ],
    );
  }

  String _getGeofenceRateDisplay(Geofence geofence) {
    switch (geofence.rateType ?? 'per_km') {
      case 'per_km':
        return '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km';
      case 'per_hour':
        return '${AppConstants.currencySymbol}${(geofence.ratePerHour ?? 0).toStringAsFixed(0)}/hour';
      case 'fixed_daily':
        return '${AppConstants.currencySymbol}${(geofence.fixedDailyRate ?? 0).toStringAsFixed(0)}/day';
      case 'hybrid':
        return '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km + ${AppConstants.currencySymbol}${(geofence.ratePerHour ?? 0).toStringAsFixed(0)}/hr';
      default:
        return '${AppConstants.currencySymbol}${(geofence.ratePerKm ?? 0).toStringAsFixed(0)}/km';
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Verification-enabled join dialog widget
class _VerificationJoinDialog extends ConsumerStatefulWidget {
  final Geofence geofence;

  const _VerificationJoinDialog({required this.geofence});

  @override
  ConsumerState<_VerificationJoinDialog> createState() => _VerificationJoinDialogState();
}

class _VerificationJoinDialogState extends ConsumerState<_VerificationJoinDialog> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _capturedImagePath;
  Position? _currentLocation;
  bool _isLocationLoading = true;
  bool _isEligibilityChecked = false;
  bool _isEligible = false;

  @override
  void initState() {
    super.initState();
    _checkEligibilityAndLocation();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _checkEligibilityAndLocation() async {
    // First get location
    await _getCurrentLocation();
    
    // Then check eligibility if we have location
    if (_currentLocation != null) {
      await _checkEligibility();
    }
    
    // Initialize camera if eligible
    if (_isEligible) {
      await _initializeCamera();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        ref.read(campaignProvider.notifier).state = 
            ref.read(campaignProvider.notifier).state.copyWith(error: 'Failed to get location: $e');
      }
    }
  }

  Future<void> _checkEligibility() async {
    if (_currentLocation == null) return;

    try {
      final isEligible = await ref.read(campaignProvider.notifier).checkGeofenceJoinEligibility(
        geofenceId: widget.geofence.id,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
      );

      if (mounted) {
        setState(() {
          _isEligible = isEligible;
          _isEligibilityChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEligible = false;
          _isEligibilityChecked = true;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to capture photo: $e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to toggle flash: $e');
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  Future<void> _submitVerification() async {
    if (_capturedImagePath == null || _currentLocation == null) return;

    final success = await ref.read(campaignProvider.notifier).joinGeofenceWithVerification(
      geofenceId: widget.geofence.id,
      imagePath: _capturedImagePath!,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      accuracy: _currentLocation!.accuracy,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${widget.geofence.name ?? 'the geofence'}!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Error is already set in provider state and will be displayed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(campaignProvider).error ?? 'Verification failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Join ${widget.geofence.name ?? 'Geofence'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(campaignState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CampaignState campaignState) {
    if (_isLocationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (!_isEligibilityChecked) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking eligibility...'),
          ],
        ),
      );
    }

    if (!_isEligible || campaignState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Join Geofence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              campaignState.error ?? 'You are not eligible to join this geofence',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Take a photo of your vehicle with the campaign sticker visible',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Camera or image preview
        Expanded(
          child: _capturedImagePath == null
              ? _buildCameraPreview()
              : _buildImagePreview(),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: _capturedImagePath == null
              ? _buildCameraControls()
              : _buildImageControls(campaignState.isJoining),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(
            _isFlashOn ? Icons.flash_on : Icons.flash_off,
            size: 32,
          ),
        ),
        GestureDetector(
          onTap: _capturePhoto,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32), // Spacer
      ],
    );
  }

  Widget _buildImageControls(bool isSubmitting) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : _retakePhoto,
            child: const Text('RETAKE'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitVerification,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('SUBMIT'),
          ),
        ),
      ],
    );
  }
}