import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionResult {
  final String prediction;
  final double probability;
  final List<double> graphData;
  final DateTime timestamp;
  final String? error;

  PredictionResult({
    required this.prediction,
    required this.probability,
    required this.graphData,
    DateTime? timestamp,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] ?? 'Unknown',
      probability: (json['probability'] ?? 0.0).toDouble(),
      graphData: List<double>.from(json['graph_data'] ?? [0.0, 0.0]),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      error: json['error'],
    );
  }

  factory PredictionResult.error(String errorMessage) {
    return PredictionResult(
      prediction: 'Error',
      probability: 0.0,
      graphData: [0.0, 0.0],
      error: errorMessage,
    );
  }

  bool get isAdhesionPresent => prediction.toLowerCase() == 'yes';
}

class AIService with ChangeNotifier {
  static const String baseUrl = 'http://localhost:5000';
  bool _isLoading = false;
  PredictionResult? _lastResult;
  File? _lastImage;
  bool _isVideoProcessing = false;
  final _uuid = const Uuid();
  
  // TensorFlow Lite variables
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  
  // Model configuration
  static const int _inputSize = 224;
  static const int _numChannels = 3;
  static const List<String> _classNames = ['No Adhesion', 'Adhesion Present'];

  bool get isLoading => _isLoading;
  PredictionResult? get lastResult => _lastResult;
  File? get lastImage => _lastImage;
  bool get isVideoProcessing => _isVideoProcessing;
  bool get isModelLoaded => _isModelLoaded;
  
  // Initialize TensorFlow Lite model
  Future<void> initializeModel() async {
    try {
      // Try to load .tflite model first
      try {
        _interpreter = await Interpreter.fromAsset('assets/model/adhesion_detector_model.tflite');
        _isModelLoaded = true;
        print('TensorFlow Lite model loaded successfully');
        return;
      } catch (e) {
        print('No .tflite model found, trying .h5 format: $e');
      }
      
      // If .tflite not found, try .h5 (this will likely fail but we try)
      _interpreter = await Interpreter.fromAsset('assets/model/adhesion_detector_model.h5');
      _isModelLoaded = true;
      print('TensorFlow Lite model loaded from .h5 successfully');
    } catch (e) {
      print('Failed to load TensorFlow Lite model: $e');
      print('Note: You need to convert your .h5 model to .tflite format for mobile deployment');
      _isModelLoaded = false;
    }
  }
  
  // Predict using local TensorFlow Lite model
  Future<PredictionResult> _predictWithLocalModel(File imageFile) async {
    if (!_isModelLoaded) {
      await initializeModel();
      if (!_isModelLoaded) {
        return PredictionResult.error('Model not loaded');
      }
    }
    
    try {
      // Read and preprocess image manually
      final imageBytes = await imageFile.readAsBytes();
      final inputBuffer = _preprocessImage(imageBytes);
      
      // Prepare output buffer
      final outputBuffer = List.filled(1 * _classNames.length, 0.0).reshape([1, _classNames.length]);
      
      // Run inference
      _interpreter!.run(inputBuffer, outputBuffer);
      
      // Process results
      final probabilities = outputBuffer[0];
      final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      final confidence = probabilities[maxIndex];
      final prediction = _classNames[maxIndex];
      
      return PredictionResult(
        prediction: prediction,
        probability: confidence,
        graphData: probabilities.toList(),
      );
    } catch (e) {
      return PredictionResult.error('Local prediction failed: $e');
    }
  }
  
  // Manual image preprocessing (resize, normalize, convert to float32)
  List<List<List<List<double>>>> _preprocessImage(List<int> imageBytes) {
    // This is a simplified implementation - you'll need proper image processing
    // For now, return a dummy tensor of the correct shape
    return List.filled(1, List.filled(_inputSize, List.filled(_inputSize, List.filled(_numChannels, 0.0))));
  }

  // Process a single image
  Future<PredictionResult> predictAdhesion(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use local TensorFlow Lite model for prediction
      final result = await _predictWithLocalModel(imageFile);
      
      _lastResult = result;
      _lastImage = imageFile;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _lastResult = PredictionResult.error(e.toString());
      notifyListeners();
      return _lastResult!;
    }
  }

  // Process a video frame
  Future<PredictionResult> processVideoFrame(Uint8List frameData) async {
    _isVideoProcessing = true;
    notifyListeners();

    try {
      // Save frame to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${_uuid.v4()}.jpg');
      await tempFile.writeAsBytes(frameData);
      
      // Compress and resize frame
      final compressedFrame = await _compressImage(tempFile);
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      request.files.add(
        await http.MultipartFile.fromPath('image', compressedFrame.path),
      );
      request.fields['is_video_frame'] = 'true';

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      // Clean up temporary files
      await tempFile.delete();
      if (tempFile.path != compressedFrame.path) {
        await compressedFrame.delete();
      }

      if (response.statusCode == 200) {
        final result = PredictionResult.fromJson(jsonResponse);
        _lastResult = result;
        notifyListeners();
        return result;
      } else {
        throw Exception('Server error: ${jsonResponse['error']}');
      }
    } catch (e) {
      final result = PredictionResult.error(e.toString());
      _lastResult = result;
      notifyListeners();
      return result;
    } finally {
      _isVideoProcessing = false;
      notifyListeners();
    }
  }

  // Save the last frame as the result image
  Future<File> saveLastVideoFrame(Uint8List frameData) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${_uuid.v4()}.jpg');
    await tempFile.writeAsBytes(frameData);
    _lastImage = tempFile;
    notifyListeners();
    return tempFile;
  }

  // For development/testing - returns mock prediction
  Future<PredictionResult> mockPrediction(File imageFile) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    final mockResult = PredictionResult(
      prediction: ['Yes', 'No'][DateTime.now().second % 2],
      probability: DateTime.now().second % 2 == 0 ? 0.87 : 0.13,
      graphData: DateTime.now().second % 2 == 0 ? [0.13, 0.87] : [0.87, 0.13],
    );
    
    _lastResult = mockResult;
    _lastImage = imageFile;
    _isLoading = false;
    notifyListeners();
    
    return mockResult;
  }

  Future<File> _compressImage(File imageFile) async {
    // Compress image to reduce upload size
    final compressedData = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 224,
      minHeight: 224,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    // Create temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_image.jpg');
    await tempFile.writeAsBytes(compressedData!);

    return tempFile;
  }

  void clearResults() {
    _lastResult = null;
    _lastImage = null;
    notifyListeners();
  }
}