// Amtrak Maps API Models
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrainPath {
  final List<LatLng> coordinates;

  const TrainPath({required this.coordinates});

  TrainPath copyWith({List<LatLng>? coordinates}) {
    return TrainPath(coordinates: coordinates ?? this.coordinates);
  }
}

class TrainStation {
  final String code;
  final LatLng? coordinates;
  final String? stationName;
  final int? stopNumber;

  const TrainStation({
    required this.code,
    this.coordinates,
    this.stationName,
    this.stopNumber,
  });

  TrainStation copyWith({
    LatLng? coordinates,
    String? stationName,
    int? stopNumber,
  }) {
    return TrainStation(
      code: code,
      coordinates: coordinates ?? this.coordinates,
      stationName: stationName ?? this.stationName,
      stopNumber: stopNumber ?? this.stopNumber,
    );
  }
}

class TrainLocation {
  final double lat;
  final double long;
  final double speed;
  final String heading;
  final String cmsId;
  final String routeName;
  final List<TrainPath> paths;
  final List<TrainStation> stations;

  const TrainLocation({
    required this.lat,
    required this.long,
    required this.speed,
    required this.heading,
    required this.cmsId,
    required this.routeName,
    required this.paths,
    required this.stations,
  });

  TrainLocation copyWith({
    List<TrainPath>? paths,
    List<TrainStation>? stations,
  }) {
    return TrainLocation(
      lat: lat,
      long: long,
      speed: speed,
      heading: heading,
      cmsId: cmsId,
      routeName: routeName,
      paths: paths ?? this.paths,
      stations: stations ?? this.stations,
    );
  }
}
