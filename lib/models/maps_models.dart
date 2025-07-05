// Amtrak Maps API Models
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrainRoute {
  final String cmsId;
  final List<List<LatLng>> paths;

  const TrainRoute({required this.cmsId, required this.paths});

  TrainRoute copyWith({
    String? cmsId,
    List<List<LatLng>>? paths,
  }) {
    return TrainRoute(
      cmsId: cmsId ?? this.cmsId,
      paths: paths ?? this.paths,
    );
  }
}

class TrainStation {
  final String code;
  final LatLng? coordinates;

  const TrainStation({required this.code, this.coordinates});

  TrainStation copyWith({LatLng? coordinates}) {
    return TrainStation(
      code: code,
      coordinates: coordinates ?? this.coordinates,
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
  final TrainRoute? route;
  final List<TrainStation> stations;

  const TrainLocation({
    required this.lat,
    required this.long,
    required this.speed,
    required this.heading,
    required this.cmsId,
    required this.routeName,
    required this.stations,
    this.route,
  });

  TrainLocation copyWith({
    TrainRoute? route,
    List<TrainStation>? stations,
  }) {
    return TrainLocation(
      lat: lat,
      long: long,
      speed: speed,
      heading: heading,
      cmsId: cmsId,
      routeName: routeName,
      route: route ?? this.route,
      stations: stations ?? this.stations,
    );
  }
}
