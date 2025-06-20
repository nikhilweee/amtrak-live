import 'package:flutter/material.dart';
import '../models.dart';
import 'train_info_card.dart';
import 'stop_card.dart';

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

    // Handle initial loading state (no existing data)
    if (widget.trainData == null && widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle null/empty state (only when not loading)
    if (widget.trainData == null && !widget.isLoading) {
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
    return Stack(
      children: [
        // Always show the scrollable content
        SingleChildScrollView(
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
        ),
        // Show loading overlay when refreshing existing data
        if (widget.isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.0),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
