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
  final GlobalKey<SearchFormState> _searchFormKey = GlobalKey<SearchFormState>();
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

  Future<void> _navigateToRecents() async {
    final result = await Navigator.of(context).push<RecentSearch>(
      MaterialPageRoute(
        builder: (context) => const RecentsPage(),
      ),
    );
    
    if (result != null) {
      // Update search form, then search
      _searchFormKey.currentState?.updateSearchFields(result.trainNumber, result.searchDate);
      _searchTrain(result.trainNumber, result.searchDate);
    }
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
          SearchForm(key: _searchFormKey, onSearch: _searchTrain, isLoading: _isLoading),

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
