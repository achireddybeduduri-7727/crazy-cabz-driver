import 'package:equatable/equatable.dart';

class PassengerModel extends Equatable {
  final String id;
  final String employeeId;
  final String fullName;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String department;
  final String homeAddress;
  final double homeLatitude;
  final double homeLongitude;
  final String? specialInstructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PassengerModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.department,
    required this.homeAddress,
    required this.homeLatitude,
    required this.homeLongitude,
    this.specialInstructions,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      department: json['department'] as String,
      homeAddress: json['home_address'] as String,
      homeLatitude: (json['home_latitude'] as num).toDouble(),
      homeLongitude: (json['home_longitude'] as num).toDouble(),
      specialInstructions: json['special_instructions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'department': department,
      'home_address': homeAddress,
      'home_latitude': homeLatitude,
      'home_longitude': homeLongitude,
      'special_instructions': specialInstructions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PassengerModel copyWith({
    String? id,
    String? employeeId,
    String? fullName,
    String? phoneNumber,
    String? profilePhotoUrl,
    String? department,
    String? homeAddress,
    double? homeLatitude,
    double? homeLongitude,
    String? specialInstructions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PassengerModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      department: department ?? this.department,
      homeAddress: homeAddress ?? this.homeAddress,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    fullName,
    phoneNumber,
    profilePhotoUrl,
    department,
    homeAddress,
    homeLatitude,
    homeLongitude,
    specialInstructions,
    isActive,
    createdAt,
    updatedAt,
  ];
}
