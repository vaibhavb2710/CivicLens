import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class PhotoEvidenceWidget extends StatefulWidget {
  const PhotoEvidenceWidget({super.key});

  @override
  State<PhotoEvidenceWidget> createState() => _PhotoEvidenceWidgetState();
}

class _PhotoEvidenceWidgetState extends State<PhotoEvidenceWidget> {
  File? _selectedFile;

  final ImagePicker _picker = ImagePicker();

  // Capture image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open camera')),
      );
    }
  }

  // Select image from files
  Future<void> _pickImageFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to select file')),
      );
    }
  }

  // Returns the selected file so parent widget can access
  File? get selectedFile => _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large tap area to open camera
        GestureDetector(
          onTap: _pickImageFromCamera,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _selectedFile == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.camera_alt,
                  color: Colors.brown,
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  'Tap to select photo (Camera)',
                  style: TextStyle(color: Colors.brown, fontSize: 16),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedFile!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Floating upload file button at bottom right
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.brown.shade600,
            onPressed: _pickImageFromFiles,
            tooltip: 'Upload photo',
            child: const Icon(Icons.upload_file),
          ),
        ),
      ],
    );
  }
}