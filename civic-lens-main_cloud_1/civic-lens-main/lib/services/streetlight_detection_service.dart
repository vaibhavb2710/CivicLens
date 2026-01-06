import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class StreetlightDetectionResult {
  final bool isStreetlight;
  final double confidence;
  final String detectionClass;
  final Position? location;
  final String? error;
  final bool hasServerGPS;
  final double? serverLatitude;
  final double? serverLongitude;
  final File? imageFile;
  final Uint8List? webImageBytes;
  final String? imageName;

  StreetlightDetectionResult({
    required this.isStreetlight,
    required this.confidence,
    required this.detectionClass,
    this.location,
    this.error,
    this.hasServerGPS = false,
    this.serverLatitude,
    this.serverLongitude,
    this.imageFile,
    this.webImageBytes,
    this.imageName,
  });

  @override
  String toString() {
    return 'StreetlightResult(isStreetlight: $isStreetlight, GPS: ${location != null ? 'Yes' : 'No'})';
  }
}

class StreetlightDetectionService {
  static String? _discoveredServerUrl;
  static DateTime? _lastDiscovery;
  static const Duration _discoveryTTL = Duration(minutes: 5);

  static const Duration _discoveryTimeout = Duration(seconds: 3);
  static const Duration _requestTimeout = Duration(seconds: 45);

  static void _log(String message) {
    debugPrint('🚦 StreetlightService: $message');
  }

  static List<String> _generatePossibleIPs() {
    List<String> possibleIPs = [];

    List<String> baseNetworks = [
      '192.168.1',
      '192.168.0',
      '10.0.0',
      '10.0.1',
      '10.221.53',
      '172.16.0',
      '192.168.2',
    ];

    for (String network in baseNetworks) {
      for (int i = 1; i <= 254; i++) {
        possibleIPs.add('$network.$i');
      }
    }

    possibleIPs.addAll(['127.0.0.1', '10.0.2.2']);

    return possibleIPs;
  }

  static Future<String?> _discoverServer() async {
    if (_discoveredServerUrl != null && _lastDiscovery != null) {
      if (DateTime.now().difference(_lastDiscovery!) < _discoveryTTL) {
        _log('✅ Using cached server: $_discoveredServerUrl');
        return _discoveredServerUrl;
      }
    }

    _log('🔍 Discovering Streetlight FastAPI server on network...');

    List<String> possibleIPs = _generatePossibleIPs();

    int batchSize = 20;
    for (int i = 0; i < possibleIPs.length; i += batchSize) {
      int end = (i + batchSize < possibleIPs.length)
          ? i + batchSize
          : possibleIPs.length;
      List<String> batch = possibleIPs.sublist(i, end);

      List<Future<String?>> tasks = batch
          .map((ip) => _testServerIP(ip))
          .toList();
      List<String?> results = await Future.wait(tasks);

      for (String? result in results) {
        if (result != null) {
          _discoveredServerUrl = result;
          _lastDiscovery = DateTime.now();
          _log('🎯 Streetlight FastAPI server found: $result');
          return result;
        }
      }

      await Future.delayed(Duration(milliseconds: 50));
    }

    _log('❌ No Streetlight FastAPI server discovered on network');
    return null;
  }

  static Future<String?> _testServerIP(String ip) async {
    try {
      String testUrl = 'http://$ip:8001'; // Port 8001 for streetlight
      final response = await http
          .get(
            Uri.parse('$testUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_discoveryTimeout);

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('status') &&
              data.containsKey('model') &&
              data.containsKey('api_type') &&
              data['api_type'] == 'streetlight_detection') {
            return testUrl;
          }
        } catch (e) {
          // Invalid JSON or wrong API
        }
      }
    } catch (e) {
      // Connection failed
    }

    return null;
  }

  static Future<Position?> _getLocationWithRetry() async {
    try {
      _log('📍 Requesting location permission...');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _log('❌ Location permission permanently denied');
        return null;
      }

      if (permission == LocationPermission.denied) {
        _log('❌ Location permission denied');
        return null;
      }

      _log('✅ Location permission granted, getting position...');

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        _log(
          '🎯 High accuracy GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
        return position;
      } catch (e) {
        _log('⚠️ High accuracy failed, trying medium accuracy...');

        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );

          _log(
            '📍 Medium accuracy GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          );
          return position;
        } catch (e2) {
          _log('❌ All GPS attempts failed: $e2');
          return null;
        }
      }
    } catch (e) {
      _log('❌ Location service error: $e');
      return null;
    }
  }

  static Future<StreetlightDetectionResult> detectStreetlight({
    File? imageFile,
    Uint8List? webImageBytes,
    String? imageName,
  }) async {
    try {
      _log('🔍 Starting streetlight detection...');

      String? serverUrl = await _discoverServer();
      if (serverUrl == null) {
        return StreetlightDetectionResult(
          isStreetlight: false,
          confidence: 0.0,
          detectionClass: 'no_server_found',
          error:
              'No Streetlight FastAPI server found. Ensure server is running on port 8001.',
        );
      }

      _log('🎯 Using server: $serverUrl');

      _log('📍 Getting GPS location...');
      Position? position = await _getLocationWithRetry();

      if (position != null) {
        _log('✅ GPS obtained successfully');
      } else {
        _log('⚠️ No GPS available - continuing without location');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/predict/'),
      );

      if (kIsWeb && webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes,
            filename: imageName ?? 'streetlight_detection.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        _log(
          '📱 Added web image: ${(webImageBytes.length / 1024).toStringAsFixed(1)}KB',
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        _log('📱 Added mobile image from: ${imageFile.path}');
      } else {
        return StreetlightDetectionResult(
          isStreetlight: false,
          confidence: 0.0,
          detectionClass: 'no_image',
          error: 'No image provided for detection',
        );
      }

      if (position != null) {
        request.fields['latitude'] = position.latitude.toString();
        request.fields['longitude'] = position.longitude.toString();
        _log(
          '📍 Sent GPS to server: ${position.latitude}, ${position.longitude}',
        );
      } else {
        request.fields['latitude'] = '0.0';
        request.fields['longitude'] = '0.0';
        _log('📍 No GPS - sending default coordinates');
      }

      _log('🚀 Sending streetlight detection request...');

      var response = await request.send().timeout(_requestTimeout);
      String responseBody = await response.stream.bytesToString();

      _log('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseStreetlightResponse(
          responseBody,
          position,
          imageFile,
          webImageBytes,
          imageName,
        );
      } else {
        _log('❌ HTTP Error: ${response.statusCode}');

        _discoveredServerUrl = null;
        _lastDiscovery = null;

        return StreetlightDetectionResult(
          isStreetlight: false,
          confidence: 0.0,
          detectionClass: 'http_error',
          error: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('❌ Streetlight detection completely failed: $e');

      _discoveredServerUrl = null;
      _lastDiscovery = null;

      return StreetlightDetectionResult(
        isStreetlight: false,
        confidence: 0.0,
        detectionClass: 'detection_failed',
        error: 'Streetlight detection failed: ${e.toString()}',
      );
    }
  }

  static StreetlightDetectionResult _parseStreetlightResponse(
    String body,
    Position? localPosition,
    File? imageFile,
    Uint8List? webImageBytes,
    String? imageName,
  ) {
    try {
      _log('📊 Parsing streetlight response...');
      Map<String, dynamic> data = json.decode(body);

      bool isStreetlight = false;
      double confidence = 0.0;
      String detectionClass = 'no_detection';
      String? error;

      if (data.containsKey('isStreetlight')) {
        isStreetlight = data['isStreetlight'] == true;
      }

      if (data.containsKey('confidence')) {
        var value = data['confidence'];
        confidence = value is num
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0.0;
      }

      if (data.containsKey('detectionClass')) {
        detectionClass = data['detectionClass'].toString();
      }

      if (data.containsKey('error')) {
        error = data['error'].toString();
      }

      bool hasServerGPS = false;
      double? serverLat, serverLon;

      if (data.containsKey('hasGPS') && data['hasGPS'] == true) {
        hasServerGPS = true;
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          serverLat = (data['latitude'] as num?)?.toDouble();
          serverLon = (data['longitude'] as num?)?.toDouble();
        }
      }

      _log('🎯 Streetlight parsing complete:');
      _log('   Streetlight detected: $isStreetlight');
      _log('   Detection class: $detectionClass');
      _log('   Local GPS: ${localPosition != null ? 'Available' : 'None'}');
      _log('   Server GPS: ${hasServerGPS ? 'Confirmed' : 'Not confirmed'}');

      return StreetlightDetectionResult(
        isStreetlight: isStreetlight,
        confidence: confidence,
        detectionClass: detectionClass,
        location: localPosition,
        error: error,
        hasServerGPS: hasServerGPS,
        serverLatitude: serverLat,
        serverLongitude: serverLon,
        imageFile: imageFile,
        webImageBytes: webImageBytes,
        imageName: imageName,
      );
    } catch (e) {
      _log('❌ Streetlight parsing failed: $e');
      return StreetlightDetectionResult(
        isStreetlight: false,
        confidence: 0.0,
        detectionClass: 'parse_error',
        error: 'Failed to parse server response: $e',
      );
    }
  }

  static Future<StreetlightDetectionResult> captureAndDetect() async {
    try {
      _log('📷 Opening camera for streetlight detection...');

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return StreetlightDetectionResult(
          isStreetlight: false,
          confidence: 0.0,
          detectionClass: 'no_camera_capture',
          error: 'No image captured from camera',
        );
      }

      _log('📷 Image captured successfully: ${pickedFile.name}');

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        _log(
          '📊 Web image size: ${(bytes.length / 1024).toStringAsFixed(1)}KB',
        );
        return await detectStreetlight(
          webImageBytes: bytes,
          imageName: pickedFile.name,
        );
      } else {
        _log('📊 Mobile image path: ${pickedFile.path}');
        return await detectStreetlight(imageFile: File(pickedFile.path));
      }
    } catch (e) {
      _log('❌ Camera capture failed: $e');
      return StreetlightDetectionResult(
        isStreetlight: false,
        confidence: 0.0,
        detectionClass: 'camera_error',
        error: 'Camera capture failed: ${e.toString()}',
      );
    }
  }

  static Future<String?> refreshServerDiscovery() async {
    _discoveredServerUrl = null;
    _lastDiscovery = null;
    _log('🔄 Forcing streetlight server rediscovery...');
    return await _discoverServer();
  }

  static String? getCurrentServerUrl() {
    return _discoveredServerUrl;
  }
}
