import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models.dart';
import 'search_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  TrainData? _trainData;
  String? _errorMessage;

  Future<void> _searchTrain(String trainNumber, DateTime date) async {
    setState(() {
      _isLoading = true;
      _trainData = null;
      _errorMessage = null;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final uri = Uri.https(
        'www.amtrak.com',
        '/dotcom/travel-service/statuses/$trainNumber',
        {'service-date': formattedDate},
      );
      final response = await http.get(
        uri,
        headers: {
          'referer': 'https://www.amtrak.com/tickets/train-status.html',
        },
      );

      setState(() {
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['data'] != null && jsonData['data'].isNotEmpty) {
            _trainData = TrainData.fromJson(jsonData['data'][0]);
          } else {
            _errorMessage = 'No train data found';
          }
        } else {
          _errorMessage = 'Error: ${response.statusCode}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildTrainInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Train Header
          SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Train ${_trainData!.trainNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _trainData!.trainName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_trainData!.originName} → ${_trainData!.destinationName}',
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(_trainData!.statusMessage),
                      backgroundColor: _getStatusColor(
                        _trainData!.statusMessage,
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stop List
          ..._trainData!.stops.map(
            (stop) => Card(
              child: ListTile(
                leading: Builder(
                  builder: (context) {
                    final (backgroundColor, textColor) = _getChipColors(stop);
                    return Chip(
                      label: Text(
                        stop.stationCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      backgroundColor: backgroundColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
                title: Text(
                  stop.stationName,
                  // style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: stop.status != null
                    ? Text(
                        stop.displayMessage ?? stop.status!,
                        style: TextStyle(
                          // fontSize: 12,
                          // fontWeight: FontWeight.w500,
                          color: _getStatusColor(stop.status!),
                        ),
                      )
                    : null,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (stop.scheduledTime != null)
                      Text(
                        'SCH: ${DateFormat('h:mm a').format(stop.scheduledTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (stop.actualTime != null)
                      Text(
                        '${stop.departuerDateTimeType == 'ACTUAL' ? 'ACT' : 'EST'}: '
                        '${DateFormat('h:mm a').format(stop.actualTime!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('ON TIME')) return Colors.green;
    if (s.contains('LATE') || s.contains('DELAY')) return Colors.orange;
    if (s.contains('CANCELLED')) return Colors.red;
    if (s.contains('DEPART') || s.contains('BOARD')) return Colors.blue;
    if (s.contains('ARRIVED')) return Colors.teal;
    return Colors.grey;
  }

  (Color background, Color text) _getChipColors(TrainStop stop) {
    final dateTimeType = stop.departuerDateTimeType.toUpperCase();
    if (dateTimeType == 'ACTUAL') {
      // ACTUAL - error color scheme for confirmed times
      return (
        Theme.of(context).colorScheme.error,
        Theme.of(context).colorScheme.onError,
      );
    } else {
      // ESTIMATE - primary color scheme for estimated times
      return (
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.onPrimary,
      );
    }
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_trainData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a train number and date to get started',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildTrainInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amtrak Live'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchForm(onSearch: _searchTrain, isLoading: _isLoading),
            const SizedBox(height: 20),

            // Results
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
