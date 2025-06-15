import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class SearchResults extends StatelessWidget {
  final bool isLoading;
  final TrainData? trainData;
  final String? errorMessage;

  const SearchResults({
    super.key,
    required this.isLoading,
    this.trainData,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (trainData == null) {
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

    return _buildTrainInfo(context);
  }

  Widget _buildTrainInfo(BuildContext context) {
    return SingleChildScrollView(
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
                      'Train ${trainData!.trainNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainData!.trainName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${trainData!.originName} → ${trainData!.destinationName}',
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(trainData!.statusMessage),
                      backgroundColor: _getStatusColor(
                        trainData!.statusMessage,
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
          ...trainData!.stops.map(
            (stop) => Card(
              child: ListTile(
                leading: Builder(
                  builder: (context) {
                    final (backgroundColor, textColor) = _getChipColors(
                      context,
                      stop,
                    );
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
                subtitle: stop.departure?.status != null
                    ? Text(
                        stop.departure?.displayMessage ?? stop.departure!.status,
                        style: TextStyle(
                          // fontSize: 12,
                          // fontWeight: FontWeight.w500,
                          color: _getStatusColor(stop.departure!.status),
                        ),
                      )
                    : null,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (stop.scheduledDepartureTime != null)
                      Text(
                        'SCH: ${DateFormat('h:mm a').format(stop.scheduledDepartureTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (stop.actualDepartureTime != null)
                      Text(
                        '${stop.departure?.dateTimeType == 'ACTUAL' ? 'ACT' : 'EST'}: '
                        '${DateFormat('h:mm a').format(stop.actualDepartureTime!)}',
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

  (Color background, Color text) _getChipColors(
    BuildContext context,
    TrainStop stop,
  ) {
    final dateTimeType = stop.departure?.dateTimeType?.toUpperCase() ?? 'ESTIMATE';
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
}
