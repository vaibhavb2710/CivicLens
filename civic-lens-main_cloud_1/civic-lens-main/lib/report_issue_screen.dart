import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../services/pothole_detection_service.dart';
import '../services/streetlight_detection_service.dart';
import '../services/trashbin_detection_service.dart'; // NEW IMPORT
import '../services/report_service.dart';
import '../services/cloudinary_uploader.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedIssueType;
  String? _selectedIssueTitle;
  String _selectedUrgency = 'Medium';
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  bool _hasVoiceNote = false;
  bool _isSubmitting = false;
  bool _isCustomTitle = false;

  bool _isDetecting = false;
  PotholeDetectionResult? _potholeDetectionResult;
  StreetlightDetectionResult? _streetlightDetectionResult;
  TrashBinDetectionResult? _trashBinDetectionResult; // NEW
  Position? _currentLocation;

  late final CloudinaryUploader _uploader;

  final List<String> _issueTypes = [
    'Potholes',
    'Streetlights',
    'Trash',
    'Parks',
    'Sanitation',
    'Traffic Signs',
    'Water Issues',
    'Other',
  ];
  final List<String> _urgencies = ['Low', 'Medium', 'High'];

  final Map<String, List<String>> _issueTitles = {
    'Potholes': [
      'Deep pothole near the junction causing traffic jams',
      'Water collects in pothole after rain → mosquito breeding ground',
      'Pothole damaged bike tire → unsafe for two-wheelers',
      'Multiple potholes in a row making road almost unusable',
      'Pothole near school/bus stop → dangerous for kids',
      'Temporary repairs keep breaking within a week',
      'Accident occurred due to large pothole not repaired',
      'Pothole under streetlight pole → risk at night',
    ],
    'Streetlights': [
      'Streetlight near house flickering on and off',
      'Several poles have stopped working → street dark and unsafe',
      'Lights stay on during the day, wasting electricity',
      'Pole bent/rusted and may fall',
      'Exposed wiring is dangerous',
      'Streetlight brightness dim → area unsafe',
      'Light cover broken → insects and glare',
      'Newly installed lights misaligned leaving dark spots',
    ],
    'Trash': [
      'Trashcan overflowing, not emptied in days',
      'Too few trashcans, garbage littered',
      'Trashcan broken (lid or wheels damaged)',
      'Stray animals pulling out garbage',
      'Foul smell due to unclean waste',
      'Mixing recyclable and non-recyclable waste',
      'People dumping debris into trashcans',
      'Trashcan blocking footpath or shop entrance',
    ],
  };

  @override
  void initState() {
    super.initState();
    _uploader = CloudinaryUploader();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position? position = await PotholeDetectionService.getCurrentLocation();
      if (mounted && position != null) {
        setState(() {
          _currentLocation = position;
          _locationController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
        _showMessage('📍 Location updated', Colors.green);
      }
    } catch (e) {
      if (mounted) _showMessage('Location failed: $e', Colors.orange);
    }
  }

  // SMART AI DETECTION - Calls different servers based on issue type
  Future<void> _smartCameraCapture() async {
    if (!mounted) return;

    // Check if issue type is selected
    if (_selectedIssueType == null) {
      _showMessage('Please select issue type first', Colors.red);
      return;
    }

    setState(() => _isDetecting = true);

    try {
      if (_selectedIssueType == 'Potholes') {
        // Call pothole detection service
        final result = await PotholeDetectionService.captureAndDetect();
        if (!mounted) return;

        setState(() {
          _potholeDetectionResult = result;
          _streetlightDetectionResult = null;
          _trashBinDetectionResult = null; // Clear other results
          _isDetecting = false;

          if (result.webImageBytes != null) {
            _webImageBytes = result.webImageBytes;
            _webImageName = result.imageName;
            _selectedImage = null;
          } else if (result.imageFile != null) {
            _selectedImage = result.imageFile;
            _webImageBytes = null;
            _webImageName = null;
          }

          if (result.location != null) {
            _currentLocation = result.location;
            _locationController.text =
                '${result.location!.latitude.toStringAsFixed(6)}, ${result.location!.longitude.toStringAsFixed(6)}';
          }

          if (result.isPothole) {
            _selectedUrgency = result.confidence > 0.5 ? 'High' : 'Medium';
            _selectedIssueTitle = null;
            _isCustomTitle = true;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'AI detected pothole';
            }
          }
        });

        _showMessage(
          result.isPothole ? '🎯 Pothole detected' : '✅ No pothole detected',
          result.isPothole ? Colors.orange : Colors.blue,
        );
      } else if (_selectedIssueType == 'Streetlights') {
        // Call streetlight detection service
        final result = await StreetlightDetectionService.captureAndDetect();
        if (!mounted) return;

        setState(() {
          _streetlightDetectionResult = result;
          _potholeDetectionResult = null;
          _trashBinDetectionResult = null; // Clear other results
          _isDetecting = false;

          if (result.webImageBytes != null) {
            _webImageBytes = result.webImageBytes;
            _webImageName = result.imageName;
            _selectedImage = null;
          } else if (result.imageFile != null) {
            _selectedImage = result.imageFile;
            _webImageBytes = null;
            _webImageName = null;
          }

          if (result.location != null) {
            _currentLocation = result.location;
            _locationController.text =
                '${result.location!.latitude.toStringAsFixed(6)}, ${result.location!.longitude.toStringAsFixed(6)}';
          }

          if (result.isStreetlight) {
            _selectedUrgency = result.confidence > 0.5 ? 'High' : 'Medium';
            _selectedIssueTitle = null;
            _isCustomTitle = true;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'AI detected streetlight';
            }
          }
        });

        _showMessage(
          result.isStreetlight
              ? '🚦 Streetlight detected'
              : '✅ No streetlight detected',
          result.isStreetlight ? Colors.orange : Colors.blue,
        );
      } else if (_selectedIssueType == 'Trash') {
        // NEW: Call trash bin detection service
        final result = await TrashBinDetectionService.captureAndDetect();
        if (!mounted) return;

        setState(() {
          _trashBinDetectionResult = result;
          _potholeDetectionResult = null;
          _streetlightDetectionResult = null; // Clear other results
          _isDetecting = false;

          if (result.webImageBytes != null) {
            _webImageBytes = result.webImageBytes;
            _webImageName = result.imageName;
            _selectedImage = null;
          } else if (result.imageFile != null) {
            _selectedImage = result.imageFile;
            _webImageBytes = null;
            _webImageName = null;
          }

          if (result.location != null) {
            _currentLocation = result.location;
            _locationController.text =
                '${result.location!.latitude.toStringAsFixed(6)}, ${result.location!.longitude.toStringAsFixed(6)}';
          }

          if (result.isTrash) {
            _selectedUrgency = result.confidence > 0.5 ? 'High' : 'Medium';
            _selectedIssueTitle = null;
            _isCustomTitle = true;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'AI detected trash bin';
            }
          }
        });

        _showMessage(
          result.isTrash ? '🗑️ Trash bin detected' : '✅ No trash bin detected',
          result.isTrash ? Colors.orange : Colors.blue,
        );
      } else {
        // For other issue types, just capture photo without AI detection
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          if (kIsWeb) {
            final bytes = await pickedFile.readAsBytes();
            setState(() {
              _webImageBytes = bytes;
              _webImageName = pickedFile.name;
              _selectedImage = null;
              _isDetecting = false;
              _potholeDetectionResult = null;
              _streetlightDetectionResult = null;
              _trashBinDetectionResult = null; // Clear all results
            });
          } else {
            setState(() {
              _selectedImage = File(pickedFile.path);
              _webImageBytes = null;
              _webImageName = null;
              _isDetecting = false;
              _potholeDetectionResult = null;
              _streetlightDetectionResult = null;
              _trashBinDetectionResult = null; // Clear all results
            });
          }
          _showMessage('📷 Photo captured', Colors.green);
        } else {
          setState(() => _isDetecting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDetecting = false);
        _showMessage('Detection failed: $e', Colors.red);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (kIsWeb) {
      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (mounted && image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _webImageName = image.name;
            _selectedImage = null;
            _potholeDetectionResult = null;
            _streetlightDetectionResult = null;
            _trashBinDetectionResult = null; // Clear all results
          });
          _showMessage('📁 Image selected from gallery', Colors.green);
        }
      } catch (e) {
        if (mounted) _showMessage('Gallery selection failed: $e', Colors.red);
      }
    } else {
      try {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (mounted && result != null && result.files.single.path != null) {
          setState(() {
            _selectedImage = File(result.files.single.path!);
            _webImageBytes = null;
            _webImageName = null;
            _potholeDetectionResult = null;
            _streetlightDetectionResult = null;
            _trashBinDetectionResult = null; // Clear all results
          });
          _showMessage('📁 Image selected from gallery', Colors.green);
        }
      } catch (e) {
        if (mounted) _showMessage('File picker failed: $e', Colors.red);
      }
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBytes != null) {
      return _buildImageWithDetection(
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _webImageBytes!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (_selectedImage != null) {
      return _buildImageWithDetection(
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isDetecting) ...[
            const CircularProgressIndicator(color: Colors.brown),
            const SizedBox(height: 10),
            Text(
              _selectedIssueType == 'Potholes'
                  ? 'AI Pothole Detection in Progress...'
                  : _selectedIssueType == 'Streetlights'
                  ? 'AI Streetlight Detection in Progress...'
                  : _selectedIssueType == 'Trash'
                  ? 'AI Trash Bin Detection in Progress...' // NEW
                  : 'Capturing Photo...',
              style: const TextStyle(color: Colors.brown, fontSize: 16),
            ),
            Text(
              _selectedIssueType == 'Potholes'
                  ? 'Analyzing image for potholes...'
                  : _selectedIssueType == 'Streetlights'
                  ? 'Analyzing image for streetlights...'
                  : _selectedIssueType == 'Trash'
                  ? 'Analyzing image for trash bins...' // NEW
                  : 'Please wait...',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ] else ...[
            Icon(
              _selectedIssueType == 'Potholes' ||
                      _selectedIssueType == 'Streetlights' ||
                      _selectedIssueType == 'Trash'
                  ? Icons.camera_enhance
                  : Icons.camera_alt,
              size: 48,
              color: Colors.brown,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedIssueType == null
                  ? 'Select Issue Type First'
                  : _selectedIssueType == 'Potholes'
                  ? 'Tap for AI Pothole Detection'
                  : _selectedIssueType == 'Streetlights'
                  ? 'Tap for AI Streetlight Detection'
                  : _selectedIssueType == 'Trash'
                  ? 'Tap for AI Trash Bin Detection' // NEW
                  : 'Tap to Take Photo',
              style: TextStyle(
                color: _selectedIssueType == null ? Colors.grey : Colors.brown,
                fontSize: 16,
              ),
            ),
            Text(
              _selectedIssueType == 'Potholes' ||
                      _selectedIssueType == 'Streetlights' ||
                      _selectedIssueType == 'Trash'
                  ? 'Camera + AI analysis in one step'
                  : 'Regular photo capture',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildImageWithDetection(Widget imageWidget) {
    bool hasDetection =
        _potholeDetectionResult != null ||
        _streetlightDetectionResult != null ||
        _trashBinDetectionResult != null; // NEW
    bool isPositiveDetection =
        (_potholeDetectionResult?.isPothole == true) ||
        (_streetlightDetectionResult?.isStreetlight == true) ||
        (_trashBinDetectionResult?.isTrash == true); // NEW

    return Stack(
      children: [
        imageWidget,
        if (hasDetection)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPositiveDetection
                    ? Colors.red.withOpacity(0.9)
                    : Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositiveDetection ? Icons.warning : Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _potholeDetectionResult != null
                          ? (_potholeDetectionResult!.isPothole
                                ? 'AI: Pothole detected'
                                : 'AI: No pothole detected')
                          : _streetlightDetectionResult != null
                          ? (_streetlightDetectionResult!.isStreetlight
                                ? 'AI: Streetlight detected'
                                : 'AI: No streetlight detected')
                          : _trashBinDetectionResult !=
                                null // NEW
                          ? (_trashBinDetectionResult!.isTrash
                                ? 'AI: Trash bin detected'
                                : 'AI: No trash bin detected')
                          : 'AI: Analysis complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedIssueType == null) {
      _showMessage('Please fill all required fields', Colors.red);
      return;
    }

    // Check AI detection requirements for Potholes, Streetlights, and Trash Bins
    if (_selectedIssueType == 'Potholes') {
      if (_potholeDetectionResult == null ||
          !_potholeDetectionResult!.isPothole) {
        _showMessage('Image rejected: No pothole detected by AI.', Colors.red);
        return;
      }
    } else if (_selectedIssueType == 'Streetlights') {
      if (_streetlightDetectionResult == null ||
          !_streetlightDetectionResult!.isStreetlight) {
        _showMessage(
          'Image rejected: No streetlight detected by AI.',
          Colors.red,
        );
        return;
      }
    } else if (_selectedIssueType == 'Trash') {
      // NEW
      if (_trashBinDetectionResult == null ||
          !_trashBinDetectionResult!.isTrash) {
        _showMessage(
          'Image rejected: No trash bin detected by AI.',
          Colors.red,
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please log in to submit reports', Colors.red);
        return;
      }

      // Upload image
      String? imageUrl;
      if (_selectedImage != null || _webImageBytes != null) {
        try {
          if (kIsWeb && _webImageBytes != null) {
            final fname = _webImageName ?? 'image.jpg';
            imageUrl = await _uploader.uploadBytes(
              _webImageBytes!,
              filename: fname,
            );
          } else if (_selectedImage != null) {
            final bytes = await _selectedImage!.readAsBytes();
            final fname = _selectedImage!.path.split('/').last;
            imageUrl = await _uploader.uploadBytes(bytes, filename: fname);
          }
        } catch (e) {
          _showMessage('Image upload failed: $e', Colors.orange);
        }
      }

      // Location payload
      Map<String, dynamic> locationData;
      if (_currentLocation != null) {
        locationData = {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'hasGPS': true,
          'location': _locationController.text.trim(),
        };
      } else {
        locationData = {
          'hasGPS': false,
          'location': _locationController.text.trim(),
        };
      }

      // AI payload based on detection type
      Map<String, dynamic>? aiDetectionData;
      if (_potholeDetectionResult != null) {
        aiDetectionData = {
          'type': 'pothole',
          'isPothole': _potholeDetectionResult!.isPothole,
          'confidence': _potholeDetectionResult!.confidence,
          'detectionClass': _potholeDetectionResult!.detectionClass,
          'hasAI': true,
        };
      } else if (_streetlightDetectionResult != null) {
        aiDetectionData = {
          'type': 'streetlight',
          'isStreetlight': _streetlightDetectionResult!.isStreetlight,
          'confidence': _streetlightDetectionResult!.confidence,
          'detectionClass': _streetlightDetectionResult!.detectionClass,
          'hasAI': true,
        };
      } else if (_trashBinDetectionResult != null) {
        // NEW
        aiDetectionData = {
          'type': 'trash',
          'isTrash': _trashBinDetectionResult!.isTrash,
          'confidence': _trashBinDetectionResult!.confidence,
          'detectionClass': _trashBinDetectionResult!.detectionClass,
          'hasAI': true,
        };
      }

      // Save report through existing service
      final reportService = ReportService();
      await reportService.submitReport(
        issueType: _selectedIssueType!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        urgencyLevel: _selectedUrgency,
        imageUrl: imageUrl,
        hasVoiceNote: _hasVoiceNote,
        locationData: locationData,
        aiDetectionData: aiDetectionData,
      );

      if (mounted) {
        _showMessage('✅ Report submitted successfully!', Colors.green);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) _showMessage('Submit failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
            icon: Icon(
              _currentLocation != null ? Icons.location_on : Icons.location_off,
              color: _currentLocation != null ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFromGallery,
        backgroundColor: const Color(0xFF8B7355),
        tooltip: 'Select from Gallery',
        child: const Icon(Icons.upload_file),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isDetecting ? null : _smartCameraCapture,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          (_potholeDetectionResult?.isPothole == true ||
                              _streetlightDetectionResult?.isStreetlight ==
                                  true ||
                              _trashBinDetectionResult?.isTrash == true) // NEW
                          ? Colors.red
                          : _selectedIssueType == null
                          ? Colors.grey
                          : Colors.brown,
                      width:
                          (_potholeDetectionResult?.isPothole == true ||
                              _streetlightDetectionResult?.isStreetlight ==
                                  true ||
                              _trashBinDetectionResult?.isTrash == true) // NEW
                          ? 2
                          : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: Center(child: _buildImagePreview()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildFormFields(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedIssueType,
          decoration: const InputDecoration(
            labelText: 'Issue Type *',
            border: OutlineInputBorder(),
          ),
          items: _issueTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedIssueType = v;
              _selectedIssueTitle = null;
              _isCustomTitle = false;
              _titleController.text = '';
              // Clear detection results when changing issue type
              _potholeDetectionResult = null;
              _streetlightDetectionResult = null;
              _trashBinDetectionResult = null; // NEW
            });
          },
          validator: (v) => v == null ? 'Select issue type' : null,
        ),
        const SizedBox(height: 16),
        if (_selectedIssueType != null &&
            _issueTitles.containsKey(_selectedIssueType) &&
            _issueTitles[_selectedIssueType]!.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _selectedIssueTitle,
            decoration: const InputDecoration(
              labelText: 'Common Issue Titles',
              hintText: 'Select or enter your own title below',
              border: OutlineInputBorder(),
            ),
            items: _issueTitles[_selectedIssueType]!
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedIssueTitle = v;
                _titleController.text = v ?? '';
                _isCustomTitle = false;
              });
            },
            isExpanded: true,
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: _selectedIssueTitle == null
                ? 'Issue Title *'
                : 'Custom Title',
            hintText: _selectedIssueTitle == null
                ? 'Enter issue title'
                : 'Or enter your own title',
            border: const OutlineInputBorder(),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Enter title' : null,
          onChanged: (v) {
            if (_selectedIssueTitle != null && v != _selectedIssueTitle) {
              setState(() {
                _isCustomTitle = true;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Latitude, Longitude or Address',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: () async {
                final position =
                    await PotholeDetectionService.getCurrentLocation();
                if (position != null) {
                  setState(() {
                    _currentLocation = position;
                    _locationController.text =
                        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
                  });
                  _showMessage('📍 Location updated', Colors.green);
                } else {
                  _showMessage('Could not get location', Colors.red);
                }
              },
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the issue in detail...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildUrgencyRow(),
        const SizedBox(height: 16),
        _buildVoiceToggle(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            // Enable/disable based on AI detection requirements
            onPressed: (_isSubmitting || _isDetectionRequired())
                ? null
                : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submitting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : const Text(
                    'Submit Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        // Show requirement message
        if (_isDetectionRequired()) ...[
          const SizedBox(height: 8),
          Text(
            _selectedIssueType == 'Potholes'
                ? 'AI must detect a pothole to submit'
                : _selectedIssueType == 'Streetlights'
                ? 'AI must detect a streetlight to submit'
                : _selectedIssueType == 'Trash'
                ? 'AI must detect a trash bin to submit' // NEW
                : '',
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  bool _isDetectionRequired() {
    if (_selectedIssueType == 'Potholes') {
      return _potholeDetectionResult == null ||
          !_potholeDetectionResult!.isPothole;
    } else if (_selectedIssueType == 'Streetlights') {
      return _streetlightDetectionResult == null ||
          !_streetlightDetectionResult!.isStreetlight;
    } else if (_selectedIssueType == 'Trash') {
      // NEW
      return _trashBinDetectionResult == null ||
          !_trashBinDetectionResult!.isTrash;
    }
    return false;
  }

  Widget _buildUrgencyRow() {
    final items = ['Low', 'Medium', 'High'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: items.map((urgency) {
            final selected = urgency == _selectedUrgency;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedUrgency = urgency),
                child: Container(
                  margin: EdgeInsets.only(right: urgency != items.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF8B7355)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Colors.transparent : Colors.grey,
                    ),
                  ),
                  child: Text(
                    urgency,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade700,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVoiceToggle() {
    return GestureDetector(
      onTap: () => setState(() => _hasVoiceNote = !_hasVoiceNote),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _hasVoiceNote
              ? const Color(0xFF8B7355).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hasVoiceNote ? const Color(0xFF8B7355) : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: _hasVoiceNote
                  ? const Color(0xFF8B7355)
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              _hasVoiceNote ? 'Voice Note Added' : 'Add Voice Note',
              style: TextStyle(
                color: _hasVoiceNote
                    ? const Color(0xFF8B7355)
                    : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
