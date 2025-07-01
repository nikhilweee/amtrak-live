import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
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

  /// Get real-time train location for a specific train number and date from Amtrak
  static Future<TrainLocation?> searchLocations(
    String trainNumber,
    DateTime date,
  ) async {
    final data = await AmtrakDecrypt.fetchAndDecryptData();

    // Parse the decrypted data to find the train with matching train number and date
    if (data['features'] != null && data['features'].isNotEmpty) {
      for (final feature in data['features']) {
        final properties = feature['properties'];
        final trainNum = properties?['TrainNum']?.toString();

        if (trainNum == trainNumber) {
          // Check if the OrigSchDep date matches the provided date
          final origSchDep = properties?['OrigSchDep']?.toString();
          if (origSchDep != null) {
            // Parse the OrigSchDep string (format: "6/30/2025 6:05:00 PM")
            final parsedDate = DateFormat(
              'M/d/yyyy h:mm:ss a',
            ).parse(origSchDep);

            // Compare only the date part (year, month, day)
            final isDateMatch =
                parsedDate.year == date.year &&
                parsedDate.month == date.month &&
                parsedDate.day == date.day;

            if (isDateMatch) {
              final geometry = feature['geometry'];
              if (geometry != null && geometry['coordinates'] != null) {
                final coordinates = geometry['coordinates'];
                if (coordinates.length >= 2) {
                  return TrainLocation(
                    lat: (coordinates[1] as num).toDouble(),
                    long: (coordinates[0] as num).toDouble(),
                    speed: double.parse(properties['Velocity'].toString()),
                    heading: properties['Heading']?.toString() ?? 'Unknown',
                  );
                }
              }
            }
          }
        }
      }
    }

    return null;
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
