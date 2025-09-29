import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

enum CameraMode { photo, video }

class CameraWidget extends StatefulWidget {
  final Function(File) onImageCaptured;
  final Function() onClose;
  final CameraMode initialMode;

  const CameraWidget({
    super.key,
    required this.onImageCaptured,
    required this.onClose,
    this.initialMode = CameraMode.photo,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isVideoMode = false;
  bool _isLiveScanning = false;
  Timer? _frameProcessingTimer;
  PredictionResult? _lastPrediction;

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.initialMode == CameraMode.video;
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopLiveScanning();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = _isFrontCamera 
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      
      if (!mounted) return;
      setState(() {});
      
      // Start live scanning if in video mode
      if (_isVideoMode && !_isLiveScanning) {
        _startLiveScanning();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
        widget.onClose();
      }
    }
  }

  Future<void> _toggleCamera() async {
    _stopLiveScanning();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  void _toggleMode() {
    setState(() {
      _isVideoMode = !_isVideoMode;
    });
    
    if (_isVideoMode) {
      _startLiveScanning();
    } else {
      _stopLiveScanning();
    }
  }

  void _startLiveScanning() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isLiveScanning = true;
      _lastPrediction = null;
    });
    
    // Process frames every 500ms
    _frameProcessingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processCurrentFrame();
    });
  }
  
  void _stopLiveScanning() {
    _frameProcessingTimer?.cancel();
    _frameProcessingTimer = null;
    
    setState(() {
      _isLiveScanning = false;
    });
  }
  
  Future<void> _processCurrentFrame() async {
    if (_controller == null || 
        !_controller!.value.isInitialized || 
        !_isLiveScanning) return;
    
    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      
      // Capture frame
      final image = await _controller!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();
      
      // Process frame
      final result = await aiService.processVideoFrame(imageBytes);
      
      if (mounted) {
        setState(() {
          _lastPrediction = result;
        });
      }
      
      // Delete temporary file
      await File(image.path).delete();
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      
      if (!_controller!.value.isInitialized) {
        throw Exception('Camera not initialized');
      }
      
      if (_isVideoMode && _isLiveScanning) {
        // In video mode, capture the current frame and stop scanning
        _stopLiveScanning();
        
        // Take a final high-quality picture
        final image = await _controller!.takePicture();
        final imageFile = File(image.path);
        
        // Pass the image to parent
        widget.onImageCaptured(imageFile);
      } else {
        // In photo mode, just take a picture
        final image = await _controller!.takePicture();
        final imageFile = File(image.path);
        widget.onImageCaptured(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (_controller?.value.isInitialized ?? false) {
                          return CameraPreview(_controller!);
                        }
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  
                  // Probability overlay for video mode
                  if (_isVideoMode && _lastPrediction != null)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _lastPrediction!.isAdhesionPresent 
                              ? Colors.red.withOpacity(0.8) 
                              : Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _lastPrediction!.isAdhesionPresent ? 'Adhesion Detected' : 'No Adhesion',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Probability: ${(_lastPrediction!.probability * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Top controls
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: widget.onClose,
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleFlash,
                              ),
                              IconButton(
                                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                                onPressed: _toggleCamera,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom controls
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mode toggle
                  TextButton(
                    onPressed: _toggleMode,
                    child: Column(
                      children: [
                        Icon(
                          _isVideoMode ? Icons.photo_camera : Icons.videocam,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isVideoMode ? 'Photo' : 'Video',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[800]!, width: 3),
                      ),
                      child: _isVideoMode && _isLiveScanning
                          ? const Icon(Icons.stop, color: Colors.red, size: 32)
                          : const SizedBox(),
                    ),
                  ),
                  
                  // Placeholder for symmetry
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flash toggle
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _toggleFlash,
              ),
              
              // Capture button
              GestureDetector(
                onTap: _isLiveScanning ? null : _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLiveScanning ? Colors.grey : Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _isLiveScanning
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : null,
                ),
              ),
              
              // Camera switch
              IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                onPressed: _toggleCamera,
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Close button
          TextButton(
            onPressed: widget.onClose,
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }


}