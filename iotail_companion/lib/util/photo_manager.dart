import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PhotoManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save photo securely as Base64
  Future<void> savePhoto(File photoFile, String key) async {
    final bytes = await photoFile.readAsBytes();
    final base64String = base64Encode(bytes);
    await _secureStorage.write(key: key, value: base64String);
  }

  // Retrieve photo as Base64 string and convert to bytes
  Future<File?> retrievePhoto(String key, String tempFileName) async {
    final base64String = await _secureStorage.read(key: key);
    if (base64String != null) {
      final bytes = base64Decode(base64String);

      // Save the bytes temporarily for usage
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/$tempFileName');
      await tempFile.writeAsBytes(bytes);

      return tempFile;
    }
    return null;
  }

  // Delete the photo from secure storage
  Future<void> deletePhoto(String key) async {
    await _secureStorage.delete(key: key);
  }
}
