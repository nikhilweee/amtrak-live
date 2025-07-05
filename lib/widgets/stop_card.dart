import 'package:flutter/material.dart';
import '../models/status_models.dart';
import '../utils.dart';

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
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Leading - Station Code Chip
                  Chip(
                    label: Text(
                      stop.stationCode,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stop.hasTrainArrived
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    backgroundColor: stop.hasTrainArrived
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.stationName),
                        if (_buildDisplayMessage() != null) ...[
                          const SizedBox(height: 4),
                          _buildDisplayMessage()!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Trailing - Time Information
                  _buildTimeChips(context),
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
    final info = stop.shouldShowDeparture ? stop.departure : stop.arrival;
    if (info?.displayMessage == null) return null;

    return Text(
      info!.displayMessage,
      style: TextStyle(color: TrainUtils.getStatusColor(info.status)),
    );
  }

  Widget _buildTimeChip(
    BuildContext context,
    String time, {
    required bool isActual,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActual
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActual
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }

  Widget _buildTimeChips(BuildContext context) {
    final scheduledTime = stop.shouldShowDeparture
        ? stop.scheduledDepartureTime
        : stop.scheduledArrivalTime;
    final actualTime = stop.shouldShowDeparture
        ? stop.actualDepartureTime
        : stop.actualArrivalTime;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (scheduledTime != null)
          _buildTimeChip(
            context,
            TrainUtils.formatTime(scheduledTime),
            isActual: false,
          ),
        if (actualTime != null) ...[
          if (scheduledTime != null) const SizedBox(height: 4),
          _buildTimeChip(
            context,
            TrainUtils.formatTime(actualTime),
            isActual: true,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedTimeSection(
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
                    Text(TrainUtils.formatTime(scheduledTime)),
                  ],
                ),
              if (actualTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(info.isActual ? 'Actual' : 'Estimated'),
                    Text(TrainUtils.formatTime(actualTime)),
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
                      style: TextStyle(
                        color: TrainUtils.getStatusColor(info.status),
                      ),
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

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stop.stationFacility != null) ...[
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            _buildExpandedTimeSection(
              'Arrival',
              Icons.arrow_downward,
              stop.scheduledArrivalTime,
              stop.actualArrivalTime,
              stop.arrival!,
            ),
          ],
          if (stop.departure != null) ...[
            const SizedBox(height: 8),
            _buildExpandedTimeSection(
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
}
