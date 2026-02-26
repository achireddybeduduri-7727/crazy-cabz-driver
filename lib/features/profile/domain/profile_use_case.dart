import 'package:image_picker/image_picker.dart';
import '../../../shared/models/driver_model.dart';

abstract class ProfileUseCase {
  Future<ProfileResult> getDriverProfile(String driverId);
  Future<ProfileResult> updateDriverProfile(
    String driverId,
    DriverModel driver,
  );
  Future<ProfileResult> uploadProfileImage(String driverId, String imagePath);
  Future<ProfileResult> uploadInsuranceDocument(
    String driverId,
    String documentPath,
  );
  Future<XFile?> pickImageFromGallery();
  Future<XFile?> pickImageFromCamera();
  Future<XFile?> pickDocument();
}

class ProfileResult {
  final bool success;
  final String? message;
  final DriverModel? driver;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  ProfileResult({
    required this.success,
    this.message,
    this.driver,
    this.imageUrl,
    this.data,
  });

  factory ProfileResult.success({
    String? message,
    DriverModel? driver,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) {
    return ProfileResult(
      success: true,
      message: message,
      driver: driver,
      imageUrl: imageUrl,
      data: data,
    );
  }

  factory ProfileResult.failure(String message) {
    return ProfileResult(success: false, message: message);
  }
}
