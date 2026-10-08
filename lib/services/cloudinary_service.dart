import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../core/constants.dart';

class CloudinaryService {
  CloudinaryPublic get _cloudinary => CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

  /// Uploads one image and returns its https URL.
  Future<String> uploadImage(File file, {String folder = 'etxespace/properties'}) async {
    final cloudName = CloudinaryConfig.cloudName.trim();
    final preset = CloudinaryConfig.uploadPreset.trim();
    if (cloudName.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME to your Cloudinary cloud name.',
      );
    }
    if (preset.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary is not configured. Set CLOUDINARY_UPLOAD_PRESET to an unsigned upload preset.',
      );
    }

    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return res.secureUrl;
    } on CloudinaryException catch (e) {
      if (e.statusCode == 401) {
        throw CloudinaryUploadException(
          'Cloudinary rejected the upload (401). Check that CLOUDINARY_CLOUD_NAME is correct and that upload preset "$preset" exists and is set to Unsigned in your Cloudinary console. ${e.message ?? ''}',
        );
      }
      throw CloudinaryUploadException(
        'Cloudinary upload failed (${e.statusCode}): ${e.message ?? e.responseString}',
      );
    }
  }

  Future<List<String>> uploadImages(List<File> files) async {
    return Future.wait(files.map((f) => uploadImage(f)));
  }
}

class CloudinaryUploadException implements Exception {
  final String message;
  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}
