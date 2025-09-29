import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../widgets/camera_widget.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _analyzeImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: \$e')),
      );
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _analyzeImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: \$e')),
      );
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    final aiService = Provider.of<AIService>(context, listen: false);
    
    try {
      // Use mock prediction for development (replace with real prediction)
      final result = await aiService.mockPrediction(imageFile);
      
      // Navigate to results screen
      Navigator.pushNamed(context, '/results');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: \$e')),
      );
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image, size: 64, color: Colors.grey),
      );
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdhesioSense'),
        elevation: 0,
        actions: [
          // Debug button to check auth state
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // Show current auth state
              final auth = Provider.of<AuthService>(context, listen: false);
              final currentUser = auth.currentUser;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Auth Debug Info'),
                  content: Text(
                    'Current User: ${currentUser?.email ?? "None"}\n'
                    'User ID: ${currentUser?.uid ?? "None"}'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await auth.signOut();
                        Navigator.pop(context);
                      },
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Debug Auth',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'View History',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adhesion Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered medical imaging analysis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main options section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Scan options cards
                    Row(
                      children: [
                        // Camera scan option
                        Expanded(
                          child: _buildOptionCard(
                            icon: Icons.camera_alt,
                            title: 'Camera Scan',
                            description: 'Take a photo to analyze',
                            color: theme.colorScheme.primary,
                            onTap: () => _openCamera(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gallery scan option
                        Expanded(
                          child: _buildOptionCard(
                            icon: Icons.photo_library,
                            title: 'Upload Image',
                            description: 'Select from gallery',
                            color: theme.colorScheme.secondary,
                            onTap: _pickImageFromGallery,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Video scan option
                    _buildOptionCard(
                      icon: Icons.videocam,
                      title: 'Live Video Scan',
                      description: 'Real-time adhesion detection',
                      color: theme.colorScheme.tertiary,
                      onTap: () => _openCamera(context, initialMode: CameraMode.video),
                      isWide: true,
                    ),
                  ],
                ),
              ),
              
              // Information section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'About AdhesioSense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This application uses AI to detect adhesions in medical images. '
                          'For professional medical use only. Results should be verified by qualified medical professionals.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: isWide ? TextAlign.start : TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: isWide ? TextAlign.start : TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _openCamera(BuildContext context, {CameraMode initialMode = CameraMode.photo}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: CameraWidget(
            initialMode: initialMode,
            onImageCaptured: (File imageFile) async {
              Navigator.of(context).pop();
              _analyzeImage(imageFile);
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}