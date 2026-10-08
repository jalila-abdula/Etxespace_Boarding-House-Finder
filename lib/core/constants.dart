import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AppColors {
  static const green = Color(0xFF00C853);
  static const greenDark = Color(0xFF00A844);
  static const dark = Color(0xFF1F2937);
  static const orange = Color(0xFFFF6B00);
  static const bg = Color(0xFFF4F8F8);
}

class CloudinaryConfig {

  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'qtr3s3f7',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'Etxespace_Cloud',
  );
}

class MapConfig {
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'com.etxespace.etxespace';
 
  static const defaultCenter = LatLng(6.5030, 124.8470);
}

class Roles {
  static const tenant = 'tenant';
  static const landlord = 'landlord';
  static const admin = 'admin';
}

class PaymentConfig {

  static const instructions =
      'Send your payment via GCash to 09XX XXX XXXX (ETXESPACE), then upload a screenshot of the receipt.';
}
