import 'package:flutter/material.dart';
import '../models.dart';
import '../services/recent_service.dart';
import '../services/search_service.dart';
import 'search_form.dart';
import 'search_results.dart';
import 'recents_page.dart';

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
      _errorMessage = null;
    });

    // Add to recent searches
    await RecentService.addRecentSearch(trainNumber, date);

    // Perform the search
    final result = await SearchService.searchTrain(trainNumber, date);

    setState(() {
      if (result.isSuccess) {
        _trainData = result.data;
        _errorMessage = null;
      } else {
        _trainData = null;
        _errorMessage = result.error;
      }
      _isLoading = false;
    });
  }

  void _navigateToRecents() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecentsPage(onSearchSelected: _searchTrain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amtrak Live'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            onPressed: _navigateToRecents,
            icon: const Icon(Icons.history),
            tooltip: 'Recent Searches',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          SizedBox(
            height: 4.0,
            child: _isLoading ? const LinearProgressIndicator() : null,
          ),

          // Search
          SearchForm(onSearch: _searchTrain, isLoading: _isLoading),

          // Results
          Expanded(
            child: SearchResults(
              trainData: _trainData,
              errorMessage: _errorMessage,
            ),
          ),
        ],
      ),
    );
  }
}
