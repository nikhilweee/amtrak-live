import 'package:flutter/material.dart';
import '../models.dart';
import '../utils.dart';

class TrainCard extends StatelessWidget {
  final TrainData trainData;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  const TrainCard({
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
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 8),
                    // Origin and destination
                    Text(
                      '${trainData.originName} → ${trainData.destinationName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    // Status message if available
                    if (trainData.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          trainData.statusMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: TrainUtils.getStatusColor(
                          trainData.statusMessage!,
                        ),
                      ),
                    ],
                    // Show detailed messages indicator when messages are available
                    if (hasDetailedMessages) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detailed Messages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
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
          ...detailedMessages.map((message) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(message),
            );
          }),
        ],
      ),
    );
  }
}
