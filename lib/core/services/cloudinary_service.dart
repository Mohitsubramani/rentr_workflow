import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/upload",
    );

    final request = http.MultipartRequest('POST', uri);

    // IMPORTANT: only upload_preset + file
    request.fields['upload_preset'] =
        CloudinaryConstants.uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      print("CLOUDINARY ERROR: $responseBody");
      throw Exception("Cloudinary upload failed");
    }
  }
}
