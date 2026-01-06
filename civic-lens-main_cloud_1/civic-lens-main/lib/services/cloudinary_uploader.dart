import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryUploader {
  static const int _timeoutSeconds = 5;
  String? _cachedServerUrl;
  DateTime? _lastDiscovery;
  static const Duration _discoveryTTL = Duration(minutes: 5);

  // FIXED: Updated port numbers to avoid conflicts
  final List<String> _potentialUrls = [
    'http://localhost:8003', // CHANGED: Port 8003 for Cloudinary
    'http://127.0.0.1:8003', // CHANGED: Port 8003
    'http://192.168.1.100:8003', // CHANGED: Port 8003
    'http://192.168.0.100:8003', // CHANGED: Port 8003
    'http://10.0.0.5:8003', // CHANGED: Port 8003
    'http://0.0.0.0:8003', // CHANGED: Port 8003
    // Add your production server URL here
    // 'https://your-production-server.com',
  ];

  void _log(String message) {
    print('☁️ CloudinaryUploader: $message');
  }

  /// ENHANCED: Better server discovery with network scanning
  Future<String> _discoverServerUrl() async {
    // Try cached URL first if available
    if (_cachedServerUrl != null && _lastDiscovery != null) {
      if (DateTime.now().difference(_lastDiscovery!) < _discoveryTTL) {
        _log('✅ Using cached server: $_cachedServerUrl');
        if (await _isServerAlive(_cachedServerUrl!)) {
          return _cachedServerUrl!;
        } else {
          _log('❌ Cached server is no longer available');
          _cachedServerUrl = null;
          _lastDiscovery = null;
        }
      }
    }

    _log('🔍 Starting Cloudinary server discovery...');

    // ENHANCED: Try network scanning like your AI detection services
    List<String> networkIPs = _generateNetworkIPs();
    List<String> allUrls = [..._potentialUrls, ...networkIPs];

    // Try each potential URL in batches for performance
    int batchSize = 10;
    for (int i = 0; i < allUrls.length; i += batchSize) {
      int end = (i + batchSize < allUrls.length)
          ? i + batchSize
          : allUrls.length;
      List<String> batch = allUrls.sublist(i, end);

      _log('🔍 Testing batch of ${batch.length} URLs...');

      List<Future<String?>> tasks = batch
          .map((url) => _testServerUrl(url))
          .toList();
      List<String?> results = await Future.wait(tasks);

      for (String? result in results) {
        if (result != null) {
          _cachedServerUrl = result;
          _lastDiscovery = DateTime.now();
          _log('🎯 Cloudinary FastAPI server found: $result');
          return result;
        }
      }

      // Small delay between batches
      if (i + batchSize < allUrls.length) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    throw Exception(
      '❌ No active Cloudinary server found on port 8003. Please ensure your FastAPI server is running.',
    );
  }

  /// ENHANCED: Generate network IPs like your AI detection services
  List<String> _generateNetworkIPs() {
    List<String> networkUrls = [];

    List<String> baseNetworks = [
      '192.168.1',
      '192.168.0',
      '10.0.0',
      '10.0.1',
      '10.221.53',
      '172.16.0',
      '192.168.2',
    ];

    // Scan common IP ranges for performance (1-50 for each network)
    for (String network in baseNetworks) {
      for (int i = 1; i <= 50; i++) {
        networkUrls.add('http://$network.$i:8003');
      }
    }

    // Add common localhost alternatives
    networkUrls.addAll([
      'http://10.0.2.2:8003', // Android emulator
    ]);

    return networkUrls;
  }

  /// Test individual server URL
  Future<String?> _testServerUrl(String url) async {
    try {
      final uri = Uri.parse('$url/');
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          // Check for your specific Cloudinary server response
          if (jsonResponse['status'] == 'ok' &&
              jsonResponse['service']?.toString().contains('Cloudinary') ==
                  true) {
            return url;
          }
        } catch (e) {
          // Fallback to body text check
          final body = response.body.toLowerCase();
          if (body.contains('status') && body.contains('ok')) {
            return url;
          }
        }
      }
    } catch (e) {
      // Connection failed, continue to next
    }
    return null;
  }

  /// IMPROVED: Better server health check
  Future<bool> _isServerAlive(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: _timeoutSeconds));

      // IMPROVED: Check for your specific FastAPI response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          // Check for your specific "status": "ok" response
          return jsonResponse['status'] == 'ok';
        } catch (e) {
          // Fallback to body text check
          final body = response.body.toLowerCase();
          return body.contains('status') && body.contains('ok');
        }
      }
      return false;
    } catch (e) {
      _log('Server check failed for $baseUrl: $e');
      return false;
    }
  }

  /// Get the upload URI for the discovered server
  Future<Uri> get _uploadUri async {
    final serverUrl = await _discoverServerUrl();
    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return Uri.parse('$cleanUrl/upload');
  }

  /// Upload bytes to Cloudinary via the FastAPI server
  Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'image.jpg',
  }) async {
    try {
      _log(
        '📤 Starting upload for file: $filename (${(bytes.length / 1024).toStringAsFixed(1)}KB)',
      );

      final uploadUri = await _uploadUri;
      _log('📤 Uploading to: $uploadUri');

      final req = http.MultipartRequest('POST', uploadUri)
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );

      final res = await req.send().timeout(
        Duration(seconds: 30), // Longer timeout for file uploads
      );

      final body = await res.stream.bytesToString();
      _log('📤 Response status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _log('✅ Upload successful');

        try {
          // IMPROVED: Parse JSON response properly
          final jsonResponse = json.decode(body);
          final secureUrl = jsonResponse['secure_url'];

          if (secureUrl != null && secureUrl.isNotEmpty) {
            _log('🔗 File uploaded to Cloudinary: $secureUrl');
            return secureUrl;
          } else {
            throw Exception('secure_url not found in JSON response');
          }
        } catch (e) {
          // Fallback to regex extraction
          final match = RegExp(
            r'"secure_url"\s*:\s*"([^"]+)"',
          ).firstMatch(body);
          if (match == null) {
            _log('❌ Response body: $body');
            throw Exception('secure_url not found in response');
          }

          final secureUrl = match.group(1)!;
          _log('🔗 File uploaded to Cloudinary: $secureUrl');
          return secureUrl;
        }
      } else {
        _log('❌ Upload failed with status ${res.statusCode}');
        _log('❌ Response body: $body');
        throw Exception('Upload failed (${res.statusCode}): $body');
      }
    } catch (e) {
      _log('❌ Upload error: $e');
      // Clear cached URL on error in case server went down
      _cachedServerUrl = null;
      _lastDiscovery = null;
      rethrow;
    }
  }

  /// Upload from file path
  Future<String> uploadFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final bytes = await file.readAsBytes();
    final filename = filePath.split('/').last;
    return uploadBytes(bytes, filename: filename);
  }

  /// Test server connectivity
  Future<bool> testConnection() async {
    try {
      _log('🔧 Testing Cloudinary server connection...');
      await _discoverServerUrl();
      _log('✅ Cloudinary server connection successful');
      return true;
    } catch (e) {
      _log('❌ Cloudinary server connection failed: $e');
      return false;
    }
  }

  /// Get current server URL (if any)
  String? get currentServerUrl => _cachedServerUrl;

  /// Manually set server URL (useful for production)
  void setServerUrl(String url) {
    _cachedServerUrl = url;
    _lastDiscovery = DateTime.now();
    _log('🔧 Server URL manually set to: $url');
  }

  /// Clear cached server URL (force rediscovery)
  void clearCache() {
    _cachedServerUrl = null;
    _lastDiscovery = null;
    _log('🔄 Server cache cleared - will rediscover on next request');
  }

  /// Force refresh server discovery
  Future<String?> refreshServerDiscovery() async {
    _cachedServerUrl = null;
    _lastDiscovery = null;
    _log('🔄 Forcing Cloudinary server rediscovery...');
    try {
      return await _discoverServerUrl();
    } catch (e) {
      _log('❌ Server rediscovery failed: $e');
      return null;
    }
  }

  /// Get server status and info
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final serverUrl = await _discoverServerUrl();
      final testUri = Uri.parse('$serverUrl/test');

      final response = await http
          .get(testUri)
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'connected': true,
          'serverUrl': serverUrl,
          'serverInfo': data,
          'lastDiscovery': _lastDiscovery?.toIso8601String(),
        };
      } else {
        return {
          'connected': false,
          'error': 'HTTP ${response.statusCode}',
          'serverUrl': serverUrl,
        };
      }
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'serverUrl': _cachedServerUrl,
      };
    }
  }

  /// Get upload statistics
  Map<String, dynamic> getStats() {
    return {
      'cachedServerUrl': _cachedServerUrl,
      'lastDiscovery': _lastDiscovery?.toIso8601String(),
      'cacheValid':
          _cachedServerUrl != null &&
          _lastDiscovery != null &&
          DateTime.now().difference(_lastDiscovery!) < _discoveryTTL,
      'potentialServers': _potentialUrls.length,
      'networkScanRange': _generateNetworkIPs().length,
    };
  }
}
