import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models.dart';

class SearchService {
  static const String _baseUrl = 'www.amtrak.com';
  static const String _referer = 'https://www.amtrak.com/tickets/train-status.html';

  /// Search for train data by train number and date
  static Future<SearchResult> searchTrain(String trainNumber, DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final uri = Uri.https(
        _baseUrl,
        '/dotcom/travel-service/statuses/$trainNumber',
        {'service-date': formattedDate},
      );
      
      final response = await http.get(
        uri,
        headers: {'referer': _referer},
      );

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
}

/// Result wrapper for search operations
class SearchResult {
  final TrainData? data;
  final String? error;
  final bool isSuccess;

  const SearchResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory SearchResult.success(TrainData data) {
    return SearchResult._(data: data, isSuccess: true);
  }

  factory SearchResult.error(String error) {
    return SearchResult._(error: error, isSuccess: false);
  }
}
