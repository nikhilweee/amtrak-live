import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models.dart';
import 'search_form.dart';
import 'search_results.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amtrak Live'),
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          // Search
          SearchForm(
            onSearch: _searchTrain,
            isLoading: _isLoading,
            hasResults: _trainData != null || _errorMessage != null,
          ),

          // Results
          Expanded(
            child: SearchResults(
              isLoading: _isLoading,
              trainData: _trainData,
              errorMessage: _errorMessage,
            ),
          ),
        ],
      ),
    );
  }
}
