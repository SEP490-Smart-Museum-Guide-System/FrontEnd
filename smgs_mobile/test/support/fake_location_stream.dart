import 'dart:async';
import 'package:geolocator/geolocator.dart';

Position gpsPosition(
  DateTime time, {
  double latitude = 10.7769,
  double longitude = 106.7009,
  double accuracy = 5,
  bool mocked = false,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: time,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

class StreamingLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission promptResult = LocationPermission.whileInUse;
  bool enabled = true;
  int prompts = 0, subscriptions = 0, cancellations = 0, positionRequests = 0;
  Position? initial;
  final positions = StreamController<Position>.broadcast(sync: true);
  final services = StreamController<ServiceStatus>.broadcast(sync: true);
  StreamingLocation() {
    positions.onCancel = () {
      cancellations++;
    };
  }
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    prompts++;
    return permission = promptResult;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Stream<ServiceStatus> getServiceStatusStream() => services.stream;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    subscriptions++;
    return positions.stream;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    return initial ?? gpsPosition(DateTime.now());
  }

  Future<void> close() async {
    await positions.close();
    await services.close();
  }
}
