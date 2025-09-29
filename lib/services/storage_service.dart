import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ScanResult {
  final String id;
  final String prediction;
  final double probability;
  final List<double> graphData;
  final String imagePath;
  final DateTime timestamp;

  ScanResult({
    required this.id,
    required this.prediction,
    required this.probability,
    required this.graphData,
    required this.imagePath,
    required this.timestamp,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      prediction: json['prediction'],
      probability: json['probability'],
      graphData: List<double>.from(json['graph_data']),
      imagePath: json['image_path'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prediction': prediction,
      'probability': probability,
      'graph_data': graphData,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy - HH:mm').format(timestamp);
  }
}

class StorageService {
  late SharedPreferences _prefs;
  final _uuid = const Uuid();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final fileName = '${_uuid.v4()}.jpg';
    final savedImage = await imageFile.copy('$path/$fileName');
    return savedImage.path;
  }

  Future<void> saveScanResult(ScanResult result) async {
    final results = await getScanHistory();
    results.insert(0, result);
    
    final jsonList = results.map((result) => result.toJson()).toList();
    await _prefs.setString('scan_history', jsonEncode(jsonList));
  }

  Future<List<ScanResult>> getScanHistory() async {
    final jsonString = _prefs.getString('scan_history');
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ScanResult.fromJson(json)).toList();
  }

  Future<void> deleteScanResult(String id) async {
    final results = await getScanHistory();
    final updatedResults = results.where((result) => result.id != id).toList();
    
    final jsonList = updatedResults.map((result) => result.toJson()).toList();
    await _prefs.setString('scan_history', jsonEncode(jsonList));
  }

  Future<void> clearHistory() async {
    await _prefs.remove('scan_history');
  }
}