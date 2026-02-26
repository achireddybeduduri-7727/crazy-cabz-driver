import 'package:hive/hive.dart';

part 'driver_model.g.dart';

@HiveType(typeId: 0)
class DriverModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fullName;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phoneNumber;

  @HiveField(4)
  int age;

  @HiveField(5)
  String? profilePhotoUrl;

  @HiveField(6)
  VehicleInfo vehicleInfo;

  @HiveField(7)
  InsuranceInfo insuranceInfo;

  @HiveField(8)
  String companyId;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.age,
    this.profilePhotoUrl,
    required this.vehicleInfo,
    required this.insuranceInfo,
    required this.companyId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      age: json['age'] ?? 0,
      profilePhotoUrl: json['profilePhotoUrl'],
      vehicleInfo: VehicleInfo.fromJson(json['vehicleInfo'] ?? {}),
      insuranceInfo: InsuranceInfo.fromJson(json['insuranceInfo'] ?? {}),
      companyId: json['companyId'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'age': age,
      'profilePhotoUrl': profilePhotoUrl,
      'vehicleInfo': vehicleInfo.toJson(),
      'insuranceInfo': insuranceInfo.toJson(),
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DriverModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    int? age,
    String? profilePhotoUrl,
    VehicleInfo? vehicleInfo,
    InsuranceInfo? insuranceInfo,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 1)
class VehicleInfo extends HiveObject {
  @HiveField(0)
  String model;

  @HiveField(1)
  String color;

  @HiveField(2)
  String plateNumber;

  @HiveField(3)
  String? year;

  @HiveField(4)
  String? make;

  VehicleInfo({
    required this.model,
    required this.color,
    required this.plateNumber,
    this.year,
    this.make,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      year: json['year'],
      make: json['make'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'color': color,
      'plateNumber': plateNumber,
      'year': year,
      'make': make,
    };
  }

  VehicleInfo copyWith({
    String? model,
    String? color,
    String? plateNumber,
    String? year,
    String? make,
  }) {
    return VehicleInfo(
      model: model ?? this.model,
      color: color ?? this.color,
      plateNumber: plateNumber ?? this.plateNumber,
      year: year ?? this.year,
      make: make ?? this.make,
    );
  }
}

@HiveType(typeId: 2)
class InsuranceInfo extends HiveObject {
  @HiveField(0)
  String provider;

  @HiveField(1)
  String policyNumber;

  @HiveField(2)
  DateTime expiryDate;

  @HiveField(3)
  String? documentUrl;

  InsuranceInfo({
    required this.provider,
    required this.policyNumber,
    required this.expiryDate,
    this.documentUrl,
  });

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) {
    return InsuranceInfo(
      provider: json['provider'] ?? '',
      policyNumber: json['policyNumber'] ?? '',
      expiryDate: DateTime.parse(
        json['expiryDate'] ?? DateTime.now().toIso8601String(),
      ),
      documentUrl: json['documentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'policyNumber': policyNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'documentUrl': documentUrl,
    };
  }

  InsuranceInfo copyWith({
    String? provider,
    String? policyNumber,
    DateTime? expiryDate,
    String? documentUrl,
  }) {
    return InsuranceInfo(
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      documentUrl: documentUrl ?? this.documentUrl,
    );
  }
}
