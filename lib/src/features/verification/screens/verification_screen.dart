import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/verification_request.dart';
import '../../../core/providers/verification_provider.dart';
import '../../../core/providers/campaign_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/widgets/loading_button.dart';
import '../widgets/verification_guide_overlay.dart';
import '../widgets/countdown_timer_widget.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final VerificationRequest? request;
  
  const VerificationScreen({super.key, this.request});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _capturedImagePath;
  Position? _currentLocation;
  Timer? _timeoutTimer;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use back camera for verification
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
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
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
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

      // Get current position
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
        _showError('Failed to get location: $e');
      }
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(
      Duration(minutes: AppConstants.verificationTimeoutMinutes),
      () {
        if (mounted) {
          _showTimeoutDialog();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);
    final currentCampaign = ref.watch(currentCampaignProvider);
    
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Camera preview
              if (_isCameraInitialized)
                _buildCameraPreview()
              else
                _buildCameraLoading(),
              
              // Verification guide overlay
              if (_isCameraInitialized && _capturedImagePath == null)
                const VerificationGuideOverlay(),
              
              // Top header with countdown
              _buildTopHeader(currentCampaign?.name ?? 'Campaign'),
              
              // Bottom controls
              _buildBottomControls(verificationState.isSubmitting),
              
              // Captured image preview
              if (_capturedImagePath != null)
                _buildImagePreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return _buildCameraLoading();
    }

    return Positioned.fill(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildCameraLoading() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(String campaignName) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // Urgent header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'VERIFICATION REQUIRED NOW!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Campaign name
            Text(
              campaignName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Countdown timer
            CountdownTimerWidget(
              duration: Duration(minutes: AppConstants.verificationTimeoutMinutes),
              onTimeout: _showTimeoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isSubmitting) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instructions
            if (_capturedImagePath == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Put the back of your keke inside the box\nMake sure the sticker dey show well well',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Action buttons
            if (_capturedImagePath == null) ...[
              Row(
                children: [
                  // Flash toggle
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Exit button
                  IconButton(
                    onPressed: _showExitConfirmation,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Preview controls
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : _retakePhoto,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('RETAKE'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      onPressed: _canSubmit() ? _submitVerification : null,
                      isLoading: isSubmitting,
                      backgroundColor: AppColors.success,
                      child: const Text('SUBMIT'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            const SizedBox(height: 100), // Space for header
            Expanded(
              child: Center(
                child: Image.file(
                  File(_capturedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 120), // Space for controls
          ],
        ),
      ),
    );
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
      _showError('Failed to toggle flash');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    if (_currentLocation == null) {
      _showError('Location not available. Please wait...');
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  bool _canSubmit() {
    return _capturedImagePath != null && 
           _currentLocation != null && 
           !_isLocationLoading;
  }

  Future<void> _submitVerification() async {
    if (!_canSubmit()) return;

    final currentCampaign = ref.read(currentCampaignProvider);
    if (currentCampaign == null) {
      _showError('No active campaign found');
      return;
    }

    final success = await ref.read(verificationProvider.notifier).submitVerification(
      campaignId: currentCampaign.id,
      imagePath: _capturedImagePath!,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      accuracy: _currentLocation!.accuracy,
    );

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        final error = ref.read(verificationProvider).error;
        _showError(error ?? 'Verification failed');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Success!'),
          ],
        ),
        content: const Text(
          'Your verification has been submitted successfully. '
          'You will receive a notification with the result shortly.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text(
          'Verification time has expired. This may affect your campaign earnings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Verification?'),
        content: const Text(
          'Are you sure you want to exit? This may affect your campaign earnings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}