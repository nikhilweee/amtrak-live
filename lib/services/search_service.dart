import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';
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
    final trainLocation = await _fetchLocation(trainNumber, date);
    if (trainLocation == null) return null;

    // Then get the route coordinates using the train's CMS ID and route name
    final routeCoordinates = await _fetchRouteCoordinates(
      trainLocation.routeName,
      trainLocation.cmsId,
    );
    if (routeCoordinates == null) return null;

    // Return a new TrainLocation with route coordinates included
    return trainLocation.copyWith(routeCoordinates: routeCoordinates);
  }

  /// Get real-time train location for a specific train number and date from Amtrak
  static Future<TrainLocation?> _fetchLocation(
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

      return TrainLocation(
        lat: (coordinates[1] as num).toDouble(),
        long: (coordinates[0] as num).toDouble(),
        speed: double.parse(properties['Velocity'].toString()),
        heading: properties['Heading']?.toString() ?? 'Unknown',
        cmsId: properties['CMSID']?.toString() ?? '',
        routeName: properties['RouteName']?.toString() ?? '',
      );
    }

    return null;
  }

  /// Get route coordinates for a specific route name
  static Future<List<LatLng>?> _fetchRouteCoordinates(
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

      // Find the feature with matching CMS ID
      for (final feature in jsonData['features']) {
        final properties = feature['properties'];
        final featureCmsId = properties?['cmsid']?.toString();

        if (featureCmsId != cmsId) continue;

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

        return coordinates.isNotEmpty ? coordinates : null;
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching route coordinates for $routeName: $e');
      return null;
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
