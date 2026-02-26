// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverModelAdapter extends TypeAdapter<DriverModel> {
  @override
  final int typeId = 0;

  @override
  DriverModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverModel(
      id: fields[0] as String,
      fullName: fields[1] as String,
      email: fields[2] as String,
      phoneNumber: fields[3] as String,
      age: fields[4] as int,
      profilePhotoUrl: fields[5] as String?,
      vehicleInfo: fields[6] as VehicleInfo,
      insuranceInfo: fields[7] as InsuranceInfo,
      companyId: fields[8] as String,
      isActive: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DriverModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.age)
      ..writeByte(5)
      ..write(obj.profilePhotoUrl)
      ..writeByte(6)
      ..write(obj.vehicleInfo)
      ..writeByte(7)
      ..write(obj.insuranceInfo)
      ..writeByte(8)
      ..write(obj.companyId)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleInfoAdapter extends TypeAdapter<VehicleInfo> {
  @override
  final int typeId = 1;

  @override
  VehicleInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleInfo(
      model: fields[0] as String,
      color: fields[1] as String,
      plateNumber: fields[2] as String,
      year: fields[3] as String?,
      make: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.model)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.plateNumber)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.make);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsuranceInfoAdapter extends TypeAdapter<InsuranceInfo> {
  @override
  final int typeId = 2;

  @override
  InsuranceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InsuranceInfo(
      provider: fields[0] as String,
      policyNumber: fields[1] as String,
      expiryDate: fields[2] as DateTime,
      documentUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InsuranceInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.provider)
      ..writeByte(1)
      ..write(obj.policyNumber)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.documentUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsuranceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
