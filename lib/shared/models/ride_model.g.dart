// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RideModelAdapter extends TypeAdapter<RideModel> {
  @override
  final int typeId = 3;

  @override
  RideModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RideModel(
      id: fields[0] as String,
      driverId: fields[1] as String,
      employeeName: fields[2] as String,
      employeePhone: fields[3] as String,
      pickupLocation: fields[4] as LocationInfo,
      dropLocation: fields[5] as LocationInfo,
      fare: fields[6] as double,
      status: fields[7] as String,
      createdAt: fields[8] as DateTime,
      startedAt: fields[9] as DateTime?,
      arrivedAt: fields[10] as DateTime?,
      pickedUpAt: fields[11] as DateTime?,
      completedAt: fields[12] as DateTime?,
      trackingPoints: (fields[13] as List?)?.cast<LocationPoint>(),
      distance: fields[14] as double?,
      duration: fields[15] as int?,
      notes: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RideModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.employeeName)
      ..writeByte(3)
      ..write(obj.employeePhone)
      ..writeByte(4)
      ..write(obj.pickupLocation)
      ..writeByte(5)
      ..write(obj.dropLocation)
      ..writeByte(6)
      ..write(obj.fare)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.startedAt)
      ..writeByte(10)
      ..write(obj.arrivedAt)
      ..writeByte(11)
      ..write(obj.pickedUpAt)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.trackingPoints)
      ..writeByte(14)
      ..write(obj.distance)
      ..writeByte(15)
      ..write(obj.duration)
      ..writeByte(16)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationInfoAdapter extends TypeAdapter<LocationInfo> {
  @override
  final int typeId = 4;

  @override
  LocationInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationInfo(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      address: fields[2] as String,
      landmark: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.landmark);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 5;

  @override
  LocationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timestamp: fields[2] as DateTime,
      speed: fields[3] as double?,
      bearing: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.speed)
      ..writeByte(4)
      ..write(obj.bearing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
