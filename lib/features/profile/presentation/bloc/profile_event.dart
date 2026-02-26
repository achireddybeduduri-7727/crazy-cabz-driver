part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String driverId;

  const ProfileLoadRequested({required this.driverId});

  @override
  List<Object> get props => [driverId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String driverId;
  final DriverModel driver;

  const ProfileUpdateRequested({required this.driverId, required this.driver});

  @override
  List<Object> get props => [driverId, driver];
}

class ProfileImageUploadRequested extends ProfileEvent {
  final String driverId;
  final String imagePath;

  const ProfileImageUploadRequested({
    required this.driverId,
    required this.imagePath,
  });

  @override
  List<Object> get props => [driverId, imagePath];
}

class ProfileInsuranceDocumentUploadRequested extends ProfileEvent {
  final String driverId;
  final String documentPath;

  const ProfileInsuranceDocumentUploadRequested({
    required this.driverId,
    required this.documentPath,
  });

  @override
  List<Object> get props => [driverId, documentPath];
}

class ProfileImagePickRequested extends ProfileEvent {
  final ImagePickerSource source;

  const ProfileImagePickRequested({required this.source});

  @override
  List<Object> get props => [source];
}

class ProfileDocumentPickRequested extends ProfileEvent {}

class ProfileClearMessage extends ProfileEvent {}

enum ImagePickerSource { gallery, camera }
