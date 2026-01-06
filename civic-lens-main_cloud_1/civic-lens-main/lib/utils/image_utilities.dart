import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtilities {
  // Compress an image file with proper handling of quality and format
  static Future<File?> compressFile(File file, {int quality = 80, int minWidth = 1024, int minHeight = 1024}) async {
    try {
      final String targetPath = file.parent.path + '/' + 'compressed_${path.basename(file.path)}';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
        keepExif: false, // Strip metadata for smaller size
      );
      
      if (result == null) {
        return file; // Return original if compression fails
      }
      
      // Convert XFile to File and check if compression actually reduced size
      File resultFile = File(result.path);
      if (await resultFile.length() < await file.length()) {
        return resultFile;
      } else {
        return file; // Return original if compression didn't help
      }
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original on error
    }
  }
  
  // Compress Uint8List data for web
  static Future<Uint8List> compressWebImage(
    Uint8List imageBytes, {
    int quality = 80, 
    int minWidth = 1024, 
    int minHeight = 1024
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );
      
      // Check if compression actually reduced size
      if (result.length < imageBytes.length) {
        return result;
      } else {
        return imageBytes; // Return original if compression didn't help
      }
    } catch (e) {
      print('Error compressing web image: $e');
      return imageBytes; // Return original on error
    }
  }
  
  // Create a unique filename for storing processed images
  static Future<String> getUniqueFilePath(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}/image_$timestamp.$extension';
  }
  
  // Convert file to optimized bytes for network transmission
  static Future<Uint8List> fileToOptimizedBytes(File file, {int maxSizeKB = 500}) async {
    try {
      final bytes = await file.readAsBytes();
      
      // If file is already smaller than target size, return as is
      if (bytes.length <= maxSizeKB * 1024) {
        return bytes;
      }
      
      // Calculate quality based on current size
      // Larger files get more compression
      final currentSizeKB = bytes.length / 1024;
      final qualityFactor = (maxSizeKB / currentSizeKB).clamp(0.5, 0.9);
      final quality = (qualityFactor * 100).round();
      
      // Compress with appropriate quality
      return await compressWebImage(
        bytes,
        quality: quality,
        minWidth: 800, // Reduced resolution for network transmission
        minHeight: 800,
      );
    } catch (e) {
      print('Error optimizing file: $e');
      // Return original bytes if available, or empty list on error
      try {
        return await file.readAsBytes();
      } catch (_) {
        return Uint8List(0);
      }
    }
  }
}