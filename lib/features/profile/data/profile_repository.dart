import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/network_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/driver_model.dart';

class ProfileRepository {
  final NetworkService _networkService = NetworkService();

  Future<Map<String, dynamic>> getDriverProfile(String driverId) async {
    try {
      final response = await _networkService.get(
        '${AppConstants.profileEndpoint}/$driverId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> updateDriverProfile({
    required String driverId,
    required DriverModel driver,
  }) async {
    try {
      final response = await _networkService.put(
        '${AppConstants.profileEndpoint}/$driverId',
        data: driver.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage({
    required String driverId,
    required String imagePath,
  }) async {
    try {
      final response = await _networkService.uploadFile(
        '${AppConstants.profileEndpoint}/$driverId/image',
        imagePath,
        onSendProgress: (sent, total) {
          // Progress callback can be used for UI updates
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> uploadInsuranceDocument({
    required String driverId,
    required String documentPath,
  }) async {
    try {
      final response = await _networkService.uploadFile(
        '${AppConstants.profileEndpoint}/$driverId/insurance',
        documentPath,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  Future<XFile?> pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
    } catch (e) {
      throw Exception('Failed to pick document: $e');
    }
  }
}
