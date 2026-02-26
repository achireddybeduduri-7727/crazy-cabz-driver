import 'package:image_picker/image_picker.dart';
import '../../../shared/models/driver_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../data/profile_repository.dart';
import 'profile_use_case.dart';

class ProfileUseCaseImpl implements ProfileUseCase {
  final ProfileRepository _profileRepository;

  ProfileUseCaseImpl(this._profileRepository);

  @override
  Future<ProfileResult> getDriverProfile(String driverId) async {
    try {
      final response = await _profileRepository.getDriverProfile(driverId);

      if (response['success'] == true) {
        final driverData = response['driver'];
        if (driverData != null) {
          final driver = DriverModel.fromJson(driverData);

          // Update local storage
          await StorageService.storeJson(
            AppConstants.userDataKey,
            driver.toJson(),
          );

          return ProfileResult.success(
            message: response['message'] ?? 'Profile loaded successfully',
            driver: driver,
          );
        }
      }

      return ProfileResult.failure(
        response['message'] ?? 'Failed to load profile',
      );
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  @override
  Future<ProfileResult> updateDriverProfile(
    String driverId,
    DriverModel driver,
  ) async {
    try {
      final updatedDriver = driver.copyWith(updatedAt: DateTime.now());

      final response = await _profileRepository.updateDriverProfile(
        driverId: driverId,
        driver: updatedDriver,
      );

      if (response['success'] == true) {
        final driverData = response['driver'];
        if (driverData != null) {
          final newDriver = DriverModel.fromJson(driverData);

          // Update local storage
          await StorageService.storeJson(
            AppConstants.userDataKey,
            newDriver.toJson(),
          );

          return ProfileResult.success(
            message: response['message'] ?? 'Profile updated successfully',
            driver: newDriver,
          );
        }
      }

      return ProfileResult.failure(
        response['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  @override
  Future<ProfileResult> uploadProfileImage(
    String driverId,
    String imagePath,
  ) async {
    try {
      final response = await _profileRepository.uploadProfileImage(
        driverId: driverId,
        imagePath: imagePath,
      );

      if (response['success'] == true) {
        final imageUrl = response['imageUrl'];

        // Update local driver data with new image URL
        final currentDriverData = StorageService.getJson(
          AppConstants.userDataKey,
        );
        if (currentDriverData != null && imageUrl != null) {
          final currentDriver = DriverModel.fromJson(currentDriverData);
          final updatedDriver = currentDriver.copyWith(
            profilePhotoUrl: imageUrl,
            updatedAt: DateTime.now(),
          );
          await StorageService.storeJson(
            AppConstants.userDataKey,
            updatedDriver.toJson(),
          );
        }

        return ProfileResult.success(
          message: response['message'] ?? 'Profile image updated successfully',
          imageUrl: imageUrl,
        );
      }

      return ProfileResult.failure(
        response['message'] ?? 'Failed to upload image',
      );
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  @override
  Future<ProfileResult> uploadInsuranceDocument(
    String driverId,
    String documentPath,
  ) async {
    try {
      final response = await _profileRepository.uploadInsuranceDocument(
        driverId: driverId,
        documentPath: documentPath,
      );

      if (response['success'] == true) {
        final documentUrl = response['documentUrl'];

        // Update local driver data with new document URL
        final currentDriverData = StorageService.getJson(
          AppConstants.userDataKey,
        );
        if (currentDriverData != null && documentUrl != null) {
          final currentDriver = DriverModel.fromJson(currentDriverData);
          final updatedInsurance = currentDriver.insuranceInfo.copyWith(
            documentUrl: documentUrl,
          );
          final updatedDriver = currentDriver.copyWith(
            insuranceInfo: updatedInsurance,
            updatedAt: DateTime.now(),
          );
          await StorageService.storeJson(
            AppConstants.userDataKey,
            updatedDriver.toJson(),
          );
        }

        return ProfileResult.success(
          message:
              response['message'] ?? 'Insurance document uploaded successfully',
          imageUrl: documentUrl,
        );
      }

      return ProfileResult.failure(
        response['message'] ?? 'Failed to upload document',
      );
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  @override
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _profileRepository.pickImageFromGallery();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _profileRepository.pickImageFromCamera();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<XFile?> pickDocument() async {
    try {
      return await _profileRepository.pickDocument();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
