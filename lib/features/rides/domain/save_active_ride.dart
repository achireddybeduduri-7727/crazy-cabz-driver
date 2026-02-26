import '../../../../core/services/storage_service.dart';
import '../../../../shared/models/ride_model.dart';

class SaveActiveRide {
  Future<void> call(RideModel ride) async {
    await StorageService.storeJson('active_ride', ride.toJson());
  }
}
