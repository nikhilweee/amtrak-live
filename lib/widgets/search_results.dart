import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

// Utility function for status colors
Color _getStatusColor(String status) {
  final s = status.toUpperCase();
  if (s.contains('ON TIME')) return Colors.green;
  if (s.contains('LATE') || s.contains('DELAY')) return Colors.orange;
  if (s.contains('EARLY')) return Colors.lightBlue;
  if (s.contains('CANCELLED')) return Colors.red;
  if (s.contains('BOARD') || s.contains('DEPART')) return Colors.blue;
  if (s.contains('ARRIVED')) return Colors.teal;
  return Colors.grey;
}

class SearchResults extends StatefulWidget {
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
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults>
    with TickerProviderStateMixin {
  // Track which stops are expanded
  final Set<String> _expandedStops = <String>{};
  // Track if train info card is expanded
  bool _isTrainInfoExpanded = false;

  void _toggleStopExpansion(String stopId) {
    setState(() {
      if (_expandedStops.contains(stopId)) {
        _expandedStops.remove(stopId);
      } else {
        _expandedStops.add(stopId);
      }
    });
  }

  void _toggleTrainInfoExpansion() {
    setState(() {
      _isTrainInfoExpanded = !_isTrainInfoExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Handle null/empty state
    if (widget.trainData == null) {
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

    // Handle data display state
    return _buildTrainResults();
  }

  Widget _buildTrainResults() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TrainInfoCard(
            trainData: widget.trainData!,
            isExpanded: _isTrainInfoExpanded,
            onToggleExpansion: _toggleTrainInfoExpansion,
          ),
          ...widget.trainData!.stops.map(
            (stop) => StopCard(
              stop: stop,
              isExpanded: _expandedStops.contains(stop.id),
              onToggleExpansion: () => _toggleStopExpansion(stop.id),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainInfoCard extends StatelessWidget {
  final TrainData trainData;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const TrainInfoCard({
    super.key,
    required this.trainData,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  bool get hasDetailedMessages => trainData.detailedMessages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: hasDetailedMessages ? onToggleExpansion : null,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Train number and name
                    Text(
                      'Train ${trainData.trainNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      trainData.trainName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Origin and destination
                    Text(
                      '${trainData.originName} → ${trainData.destinationName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    // Status message if available
                    if (trainData.statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Chip(
                        label: Text(
                          trainData.statusMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getStatusColor(
                          trainData.statusMessage!,
                        ),
                      ),
                    ],
                    // Show detailed messages indicator when messages are available
                    if (hasDetailedMessages) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detailed Messages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Animated expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: isExpanded
                  ? _buildExpandedContent(context)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final detailedMessages = trainData.detailedMessages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          ...detailedMessages.map((message) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(message),
            );
          }),
        ],
      ),
    );
  }
}

class StopCard extends StatelessWidget {
  final TrainStop stop;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const StopCard({
    super.key,
    required this.stop,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpansion,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Leading - Station Code Chip
                  Chip(
                    label: Text(
                      stop.stationCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            stop.departure?.dateTimeType?.toUpperCase() ==
                                'ACTUAL'
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                    backgroundColor:
                        stop.departure?.dateTimeType?.toUpperCase() == 'ACTUAL'
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.stationName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_buildDisplayMessage() != null) ...[
                          const SizedBox(height: 4),
                          _buildDisplayMessage()!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Trailing - Time Information
                  Builder(
                    builder: (context) {
                      final showDeparture = _shouldShowDeparture();
                      final scheduledTime = showDeparture
                          ? stop.scheduledDepartureTime
                          : stop.scheduledArrivalTime;
                      final actualTime = showDeparture
                          ? stop.actualDepartureTime
                          : stop.actualArrivalTime;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (scheduledTime != null)
                            _buildTimeChip(
                              DateFormat('h:mm a').format(scheduledTime),
                              isActual: false,
                            ),
                          if (actualTime != null) ...[
                            if (scheduledTime != null)
                              const SizedBox(height: 4),
                            _buildTimeChip(
                              DateFormat('h:mm a').format(actualTime),
                              isActual: true,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Animated expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: isExpanded
                  ? _buildExpandedContent(context)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildDisplayMessage() {
    final info = _shouldShowDeparture() ? stop.departure : stop.arrival;
    if (info?.displayMessage == null) return null;

    return Text(
      info!.displayMessage,
      style: TextStyle(color: _getStatusColor(info.status)),
    );
  }

  Widget _buildTimeChip(String time, {required bool isActual}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActual ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActual ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }

  // Helper methods
  bool _shouldShowDeparture() {
    // Show departure if train has actually departed (departure is actual)
    return stop.departure?.dateTimeType?.toUpperCase() == 'ACTUAL';
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stop.stationFacility != null) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Facility',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(stop.stationFacility!),
              ],
            ),
          ],
          if (stop.arrival != null) ...[
            const Divider(height: 20),
            _buildTimeSection(
              'Arrival',
              Icons.arrow_downward,
              stop.scheduledArrivalTime,
              stop.actualArrivalTime,
              stop.arrival!,
            ),
          ],
          if (stop.departure != null) ...[
            const Divider(height: 20),
            _buildTimeSection(
              'Departure',
              Icons.arrow_upward,
              stop.scheduledDepartureTime,
              stop.actualDepartureTime,
              stop.departure!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    IconData icon,
    DateTime? scheduledTime,
    DateTime? actualTime,
    ArrivalDeparture info,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheduledTime != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scheduled'),
                    Text(DateFormat('h:mm a').format(scheduledTime)),
                  ],
                ),
              if (actualTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      info.dateTimeType?.toUpperCase() == 'ACTUAL'
                          ? 'Actual'
                          : 'Estimated',
                    ),
                    Text(DateFormat('h:mm a').format(actualTime)),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status'),
                  Expanded(
                    child: Text(
                      info.displayMessage,
                      style: TextStyle(color: _getStatusColor(info.status)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              if (info.gateNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('Gate'), Text(info.gateNumber!)],
                ),
              ],
              if (info.trackNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('Track'), Text(info.trackNumber!)],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
