import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/maps_models.dart';
import '../models/status_models.dart';
import 'amtrak_decrypt.dart';

class SearchService {
  /// Refresh station and route cache if needed (call on app startup)
  static Future<void> refreshCacheIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final stationFile = File('${dir.path}/stations.json');
    final routesFile = File('${dir.path}/routes.json');

    Future<bool> needsRefresh(File file) async {
      if (!await file.exists()) return true;
      final lastMod = await file.lastModified();
      return DateTime.now().difference(lastMod) > Duration(hours: 24);
    }

    debugPrint("Checking for JSON Assets");

    if (await needsRefresh(stationFile)) {
      debugPrint("fetching stations.json");
      final data = await AmtrakDecrypt.getStationData();
      await stationFile.writeAsString(json.encode(data));
    }

    if (await needsRefresh(routesFile)) {
      debugPrint("fetching routes.json");
      final uri = Uri.parse(
        'https://maps.amtrak.com/services/MapDataService/stations/nationalRoute',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        await routesFile.writeAsString(response.body);
      }
    }
  }

  static const String _baseUrl = 'www.amtrak.com';
  static const String _referer =
      'https://www.amtrak.com/tickets/train-status.html';

  // Search for train data by train number and date
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

  // Get train location and its route coordinates for a specific train number and date
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

  // Get real-time train location for a specific train number and date from Amtrak
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

  // Get route coordinates for a specific route name
  static Future<List<List<LatLng>>?> _fetchTrainRoute(
    String routeName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final routesFile = File('${dir.path}/routes.json');
      if (!await routesFile.exists()) return null;
      final jsonStr = await routesFile.readAsString();
      final jsonData = json.decode(jsonStr);

      if (jsonData['features'] == null || jsonData['features'].isEmpty) {
        return null;
      }

      final List<List<LatLng>> allPaths = [];

      for (final feature in jsonData['features']) {
        final name = feature['properties']?['name'] ?? '';
        if (!name.contains(routeName)) continue;
        final geometry = feature['geometry'];
        if (geometry == null) continue;
        final type = geometry['type'];
        final coords = geometry['coordinates'];
        if (coords == null || coords is! List || coords.isEmpty) continue;

        if (type == 'MultiLineString') {
          for (final line in coords) {
            if (line == null || line is! List || line.isEmpty) continue;
            final coordinates = <LatLng>[];
            for (final coordPair in line) {
              if (coordPair is! List || coordPair.length < 2) continue;
              coordinates.add(
                LatLng(
                  (coordPair[1] as num).toDouble(),
                  (coordPair[0] as num).toDouble(),
                ),
              );
            }
            if (coordinates.isNotEmpty) allPaths.add(coordinates);
          }
          continue;
        }

        if (type == 'LineString') {
          final coordinates = <LatLng>[];
          for (final coordPair in coords) {
            if (coordPair is! List || coordPair.length < 2) continue;
            coordinates.add(
              LatLng(
                (coordPair[1] as num).toDouble(),
                (coordPair[0] as num).toDouble(),
              ),
            );
          }
          if (coordinates.isNotEmpty) allPaths.add(coordinates);
        }
      }

      debugPrint('Number of paths found: ${allPaths.length}');

      return allPaths.isNotEmpty ? allPaths : null;
    } catch (e) {
      debugPrint('Error reading cached routes: $e');
      return null;
    }
  }

  // Get station coordinates for all stations from Amtrak station data
  static Future<List<TrainStation>> _fetchTrainStations(
    TrainLocation trainLocation,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stationFile = File('${dir.path}/stations.json');
      if (!await stationFile.exists()) return trainLocation.stations;
      final jsonStr = await stationFile.readAsString();
      final data = json.decode(jsonStr);

      if (data['StationsDataResponse'] == null ||
          data['StationsDataResponse']['features'] == null) {
        return trainLocation.stations;
      }

      final Map<String, Map<String, dynamic>> stationInfoMap = {};
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

        final LatLng latLng = LatLng(
          (coordinates[1] as num).toDouble(), // latitude
          (coordinates[0] as num).toDouble(), // longitude
        );
        final String? stationName = properties['StationName']?.toString();

        stationInfoMap[stationCode] = {
          'coordinates': latLng,
          'stationName': stationName,
        };
      }

      debugPrint('Loaded ${stationInfoMap.length} station coordinates');

      final List<TrainStation> updatedStations = [];
      for (int i = 0; i < trainLocation.stations.length; i++) {
        final station = trainLocation.stations[i];
        final stopNumber = i + 1;
        if (stationInfoMap.containsKey(station.code)) {
          final info = stationInfoMap[station.code]!;
          updatedStations.add(
            station.copyWith(
              coordinates: info['coordinates'] as LatLng?,
              stationName: info['stationName'] as String?,
              stopNumber: stopNumber,
            ),
          );
        } else {
          updatedStations.add(station.copyWith(stopNumber: stopNumber));
        }
      }

      return updatedStations;
    } catch (e) {
      debugPrint('Error reading cached station data: $e');
      return trainLocation.stations;
    }
  }
}

// Result wrapper for search operations
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
