import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'chat_screen.dart';
import '../services/image_analysis_service.dart';

class ImageDiagnosisScreen extends StatefulWidget {
  const ImageDiagnosisScreen({super.key});

  @override
  State<ImageDiagnosisScreen> createState() => _ImageDiagnosisScreenState();
}

class _ImageDiagnosisScreenState extends State<ImageDiagnosisScreen> {
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _medicalDescription;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = bytes;
          _medicalDescription = null;
        });
      }
    } catch (e) {
      print('Error selecting image: $e');
      
      String errorMessage = 'Error selecting image: $e';
      
      // Provide more specific error messages
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied: $e\n\nPlease grant camera and photo library permissions in device settings.';
      } else if (e.toString().contains('camera')) {
        errorMessage = 'Camera error: $e\n\nPlease check if the camera is available and not being used by another app.';
      } else if (e.toString().contains('gallery') || e.toString().contains('photo')) {
        errorMessage = 'Gallery error: $e\n\nPlease check if you have photos in your gallery and try again.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _processImage() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Basic validation
      if (_selectedImageBytes!.isEmpty) {
        throw Exception('Image file is empty');
      }
      
      
      // Analyze with the medical AI model using the bytes directly
      final String analysis = await ImageAnalysisService.analyzeMedicalImage(_selectedImageBytes!);
      
      setState(() {
        _medicalDescription = analysis;
        _isProcessing = false;
      });

    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
      });
      
      String errorMessage = 'Error processing image: $e';
      
      // Provide more specific error messages
      if (e.toString().contains('model')) {
        errorMessage = 'AI model error: $e\n\nPlease make sure the medical model is properly installed and loaded.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error: $e\n\nPlease check your internet connection and try again.';
      } else if (e.toString().contains('memory') || e.toString().contains('out of memory')) {
        errorMessage = 'Memory error: $e\n\nThe image is too large or the device has insufficient memory.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission error: $e\n\nPlease grant camera and photo library permissions in device settings.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat() {
    if (_medicalDescription != null) {
      final formattedMessage = ImageAnalysisService.formatAnalysisForChat(_medicalDescription!);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            initialMessage: formattedMessage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Diagnosis'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection buttons
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Show analyze button only when image is selected
            if (_selectedImageFile != null && !_isProcessing && _medicalDescription == null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Image Selected - Ready to Analyze',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _processImage,
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Analyze Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Show image being analyzed (before analysis results)
            if (_isProcessing && _selectedImageBytes != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Analyzing Image...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('AI is analyzing your medical image...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Medical description
            if (_medicalDescription != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Medical Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _medicalDescription!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToChat,
                          icon: const Icon(Icons.chat),
                          label: const Text('Discuss with AI Assistant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
          ],
        ),
      ),
    );
  }
} 