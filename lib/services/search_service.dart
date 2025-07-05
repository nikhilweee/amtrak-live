import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/maps_models.dart';
import '../models/status_models.dart';
import 'amtrak_decrypt.dart';

class SearchService {
  static const String _baseUrl = 'www.amtrak.com';
  static const String _referer =
      'https://www.amtrak.com/tickets/train-status.html';

  /// Search for train data by train number and date
  static Future<SearchResult> searchTrain(
    String trainNumber,
    DateTime date,
  ) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final uri = Uri.https(
        _baseUrl,
        '/dotcom/travel-service/statuses/$trainNumber',
        {'service-date': formattedDate},
      );

      final response = await http.get(uri, headers: {'referer': _referer});

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data'].isNotEmpty) {
          final trainData = TrainData.fromJson(jsonData['data'][0]);
          return SearchResult.success(trainData);
        } else {
          return SearchResult.error('No train data found');
        }
      } else {
        return SearchResult.error('Error: ${response.statusCode}');
      }
    } catch (e) {
      return SearchResult.error('Error: ${e.toString()}');
    }
  }

  /// Get train location and its route coordinates for a specific train number and date
  static Future<TrainLocation?> searchRoute(
    String trainNumber,
    DateTime date,
  ) async {
    // First get the train location
    final trainLocation = await _fetchTrainLocation(trainNumber, date);
    if (trainLocation == null) return null;

    // Then get the route coordinates using the train's CMS ID and route name
    final routePaths = await _fetchTrainRoute(
      trainLocation.routeName,
      trainLocation.cmsId,
    );
    if (routePaths == null || routePaths.isEmpty) return null;

    // Get station coordinates for the train's stations
    final stationsWithCoordinates = await _fetchTrainStations(trainLocation);

    // Create TrainPath objects from the fetched paths
    final trainPaths = routePaths
        .map((path) => TrainPath(coordinates: path))
        .toList();

    // Return a new TrainLocation with paths and updated stations
    return trainLocation.copyWith(
      paths: trainPaths,
      stations: stationsWithCoordinates,
    );
  }

  /// Get real-time train location for a specific train number and date from Amtrak
  static Future<TrainLocation?> _fetchTrainLocation(
    String trainNumber,
    DateTime date,
  ) async {
    final data = await AmtrakDecrypt.getTrainData();

    if (data['features'] == null || data['features'].isEmpty) {
      return null;
    }

    for (final feature in data['features']) {
      final properties = feature['properties'];
      final trainNum = properties?['TrainNum']?.toString();

      if (trainNum != trainNumber) continue;

      final origSchDep = properties?['OrigSchDep']?.toString();
      if (origSchDep == null) continue;

      // Parse the OrigSchDep string (format: "6/30/2025 6:05:00 PM")
      final parsedDate = DateFormat('M/d/yyyy h:mm:ss a').parse(origSchDep);

      final isDateMatch =
          parsedDate.year == date.year &&
          parsedDate.month == date.month &&
          parsedDate.day == date.day;
      if (!isDateMatch) continue;

      final geometry = feature['geometry'];
      if (geometry == null || geometry['coordinates'] == null) continue;

      final coordinates = geometry['coordinates'];
      if (coordinates.length < 2) continue;

      // Parse station data
      final List<TrainStation> stationCodes = [];
      for (int i = 1; i <= 50; i++) {
        final stationKey = 'Station$i';
        final stationData = properties?[stationKey]?.toString();

        if (stationData != null && stationData.isNotEmpty) {
          try {
            final stationJson = json.decode(stationData);
            final stationCode = stationJson['code']?.toString();
            if (stationCode != null && stationCode.isNotEmpty) {
              stationCodes.add(TrainStation(code: stationCode));
            }
          } catch (e) {
            // Skip invalid JSON station data
            debugPrint('Error parsing station data for $stationKey: $e');
          }
        }
      }

      return TrainLocation(
        lat: (coordinates[1] as num).toDouble(),
        long: (coordinates[0] as num).toDouble(),
        speed: double.parse(properties['Velocity'].toString()),
        heading: properties['Heading']?.toString() ?? 'Unknown',
        cmsId: properties['CMSID']?.toString() ?? '',
        routeName: properties['RouteName']?.toString() ?? '',
        paths: [], // Empty paths initially, will be populated later
        stations: stationCodes,
      );
    }

    return null;
  }

  /// Get route coordinates for a specific route name
  static Future<List<List<LatLng>>?> _fetchTrainRoute(
    String routeName,
    String cmsId,
  ) async {
    try {
      final uri = Uri.parse(
        'https://maps.amtrak.com/services/MapDataService/stations/nationalRoute',
      ).replace(queryParameters: {'routeName': routeName});

      final response = await http.get(uri);

      if (response.statusCode != 200) return null;

      final jsonData = json.decode(response.body);

      if (jsonData['features'] == null || jsonData['features'].isEmpty) {
        return null;
      }

      final List<List<LatLng>> allPaths = [];

      // Collect paths from all features (no CMS ID filtering)
      for (final feature in jsonData['features']) {
        final geometry = feature['geometry'];
        if (geometry == null || geometry['coordinates'] == null) continue;

        final coordinatesList = geometry['coordinates'];
        if (coordinatesList is! List || coordinatesList.isEmpty) continue;

        final List<LatLng> coordinates = [];

        // Iterate over the coordinate pairs in the LineString
        for (final coordPair in coordinatesList) {
          if (coordPair is List && coordPair.length >= 2) {
            coordinates.add(
              LatLng(
                (coordPair[1] as num).toDouble(), // latitude
                (coordPair[0] as num).toDouble(), // longitude
              ),
            );
          }
        }

        if (coordinates.isNotEmpty) {
          allPaths.add(coordinates);
        }
      }

      debugPrint('Number of paths found: ${allPaths.length}');

      return allPaths.isNotEmpty ? allPaths : null;
    } catch (e) {
      debugPrint('Error fetching route coordinates for $routeName: $e');
      return null;
    }
  }

  /// Get station coordinates for all stations from Amtrak station data
  static Future<List<TrainStation>> _fetchTrainStations(
    TrainLocation trainLocation,
  ) async {
    try {
      final data = await AmtrakDecrypt.getStationData();

      if (data['StationsDataResponse'] == null ||
          data['StationsDataResponse']['features'] == null) {
        return trainLocation.stations;
      }

      final Map<String, LatLng> stationMap = {};
      final features = data['StationsDataResponse']['features'] as List;

      for (final feature in features) {
        if (feature['properties'] == null || feature['geometry'] == null) {
          continue;
        }

        final properties = feature['properties'];
        final geometry = feature['geometry'];

        final stationCode = properties['Code']?.toString();
        if (stationCode == null || stationCode.isEmpty) continue;

        final coordinates = geometry['coordinates'];
        if (coordinates == null || coordinates.length < 2) continue;

        stationMap[stationCode] = LatLng(
          (coordinates[1] as num).toDouble(), // latitude
          (coordinates[0] as num).toDouble(), // longitude
        );
      }

      debugPrint('Loaded ${stationMap.length} station coordinates');

      // Update the train location stations with coordinates
      final List<TrainStation> updatedStations = [];
      for (final station in trainLocation.stations) {
        if (stationMap.containsKey(station.code)) {
          updatedStations.add(
            station.copyWith(coordinates: stationMap[station.code]),
          );
        } else {
          // Keep original station data if no coordinates found
          updatedStations.add(station);
        }
      }

      return updatedStations;
    } catch (e) {
      debugPrint('Error fetching station data: $e');
      return trainLocation.stations;
    }
  }
}

/// Result wrapper for search operations
class SearchResult {
  final TrainData? data;
  final String? error;
  final bool isSuccess;

  const SearchResult._({this.data, this.error, required this.isSuccess});

  factory SearchResult.success(TrainData data) {
    return SearchResult._(data: data, isSuccess: true);
  }

  factory SearchResult.error(String error) {
    return SearchResult._(error: error, isSuccess: false);
  }
}
