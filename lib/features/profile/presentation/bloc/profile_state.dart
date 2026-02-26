part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final DriverModel driver;

  const ProfileLoaded({required this.driver});

  @override
  List<Object> get props => [driver];
}

class ProfileUpdateSuccess extends ProfileState {
  final DriverModel driver;
  final String message;

  const ProfileUpdateSuccess({required this.driver, required this.message});

  @override
  List<Object> get props => [driver, message];
}

class ProfileImageUploadSuccess extends ProfileState {
  final String imageUrl;
  final String message;

  const ProfileImageUploadSuccess({
    required this.imageUrl,
    required this.message,
  });

  @override
  List<Object> get props => [imageUrl, message];
}

class ProfileImagePicked extends ProfileState {
  final String imagePath;

  const ProfileImagePicked({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

class ProfileDocumentPicked extends ProfileState {
  final String documentPath;

  const ProfileDocumentPicked({required this.documentPath});

  @override
  List<Object> get props => [documentPath];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}
