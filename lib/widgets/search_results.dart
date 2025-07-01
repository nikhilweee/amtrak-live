import 'package:flutter/material.dart';
import '../models.dart';
import 'train_card.dart';
import 'stop_card.dart';
import 'map_widget.dart';

class SearchResults extends StatefulWidget {
  final TrainData? trainData;
  final String? errorMessage;
  final TrainLocation? trainLocation;

  const SearchResults({
    super.key,
    this.trainData,
    this.errorMessage,
    this.trainLocation,
  });

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  // Track which stops are expanded
  final Set<String> _expandedStops = <String>{};
  // Track if train info card is expanded
  bool _isTrainInfoExpanded = false;

  void _toggleStopExpansion(String stopId) {
    setState(
      () => _expandedStops.contains(stopId)
          ? _expandedStops.remove(stopId)
          : _expandedStops.add(stopId),
    );
  }

  void _toggleTrainInfoExpansion() {
    setState(() {
      _isTrainInfoExpanded = !_isTrainInfoExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle error or empty state
    if (widget.errorMessage != null || widget.trainData == null) {
      final isError = widget.errorMessage != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.train,
              size: 48,
              color: isError ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isError
                  ? widget.errorMessage!
                  : 'Enter a train number and date to search',
              style: const TextStyle(color: Colors.grey),
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
          TrainCard(
            trainData: widget.trainData!,
            isExpanded: _isTrainInfoExpanded,
            onToggleExpansion: _toggleTrainInfoExpansion,
          ),
          // Map showing train location (only show when available)
          if (widget.trainLocation != null)
            MapWidget(trainLocation: widget.trainLocation!),
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
