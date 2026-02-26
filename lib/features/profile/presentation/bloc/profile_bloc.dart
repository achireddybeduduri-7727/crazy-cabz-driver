import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/models/driver_model.dart';
import '../../domain/profile_use_case.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileUseCase _profileUseCase;

  ProfileBloc(this._profileUseCase) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileImageUploadRequested>(_onProfileImageUploadRequested);
    on<ProfileInsuranceDocumentUploadRequested>(
      _onProfileInsuranceDocumentUploadRequested,
    );
    on<ProfileImagePickRequested>(_onProfileImagePickRequested);
    on<ProfileDocumentPickRequested>(_onProfileDocumentPickRequested);
    on<ProfileClearMessage>(_onProfileClearMessage);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await _profileUseCase.getDriverProfile(event.driverId);

    if (result.success && result.driver != null) {
      emit(ProfileLoaded(driver: result.driver!));
    } else {
      emit(ProfileError(message: result.message ?? 'Failed to load profile'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await _profileUseCase.updateDriverProfile(
      event.driverId,
      event.driver,
    );

    if (result.success && result.driver != null) {
      emit(
        ProfileUpdateSuccess(
          driver: result.driver!,
          message: result.message ?? 'Profile updated successfully',
        ),
      );
    } else {
      emit(ProfileError(message: result.message ?? 'Failed to update profile'));
    }
  }

  Future<void> _onProfileImageUploadRequested(
    ProfileImageUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await _profileUseCase.uploadProfileImage(
      event.driverId,
      event.imagePath,
    );

    if (result.success && result.imageUrl != null) {
      emit(
        ProfileImageUploadSuccess(
          imageUrl: result.imageUrl!,
          message: result.message ?? 'Profile image updated successfully',
        ),
      );
    } else {
      emit(ProfileError(message: result.message ?? 'Failed to upload image'));
    }
  }

  Future<void> _onProfileInsuranceDocumentUploadRequested(
    ProfileInsuranceDocumentUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await _profileUseCase.uploadInsuranceDocument(
      event.driverId,
      event.documentPath,
    );

    if (result.success) {
      emit(
        ProfileImageUploadSuccess(
          imageUrl: result.imageUrl ?? '',
          message: result.message ?? 'Insurance document uploaded successfully',
        ),
      );
    } else {
      emit(
        ProfileError(message: result.message ?? 'Failed to upload document'),
      );
    }
  }

  Future<void> _onProfileImagePickRequested(
    ProfileImagePickRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      XFile? pickedFile;

      if (event.source == ImagePickerSource.gallery) {
        pickedFile = await _profileUseCase.pickImageFromGallery();
      } else {
        pickedFile = await _profileUseCase.pickImageFromCamera();
      }

      if (pickedFile != null) {
        emit(ProfileImagePicked(imagePath: pickedFile.path));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileDocumentPickRequested(
    ProfileDocumentPickRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final pickedFile = await _profileUseCase.pickDocument();

      if (pickedFile != null) {
        emit(ProfileDocumentPicked(documentPath: pickedFile.path));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileClearMessage(
    ProfileClearMessage event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileError ||
        state is ProfileUpdateSuccess ||
        state is ProfileImageUploadSuccess) {
      emit(ProfileInitial());
    }
  }
}
