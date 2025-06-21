import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models.dart';

class RecentService {
  static const String _key = 'recent_searches';
  static const int _maxSearches = 50;

  // Load recent searches from SharedPreferences
  static Future<List<RecentSearch>> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? searchesJson = prefs.getString(_key);

    if (searchesJson == null) return [];

    try {
      final List<dynamic> searchesList = json.decode(searchesJson);
      return searchesList.map((json) => RecentSearch.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  // Save recent searches to SharedPreferences
  static Future<void> saveRecentSearches(List<RecentSearch> searches) async {
    final prefs = await SharedPreferences.getInstance();
    final String searchesJson = json.encode(
      searches.map((search) => search.toJson()).toList(),
    );
    await prefs.setString(_key, searchesJson);
  }

  // Add a new search to recent searches
  static Future<void> addRecentSearch(
    String trainNumber,
    DateTime searchDate,
  ) async {
    final searches = await loadRecentSearches();
    final now = DateTime.now();

    // Remove existing search if it matches (same train and date)
    searches.removeWhere((search) => search.matches(trainNumber, searchDate));

    // Add new search at the beginning
    searches.insert(
      0,
      RecentSearch(
        trainNumber: trainNumber,
        searchDate: searchDate,
        timestamp: now,
      ),
    );

    // Keep only the most recent searches (up to _maxSearches)
    if (searches.length > _maxSearches) {
      searches.removeRange(_maxSearches, searches.length);
    }

    await saveRecentSearches(searches);
  }

  // Remove a specific search
  static Future<void> removeRecentSearch(RecentSearch searchToRemove) async {
    final searches = await loadRecentSearches();
    searches.removeWhere(
      (search) =>
          search.trainNumber == searchToRemove.trainNumber &&
          search.searchDate == searchToRemove.searchDate &&
          search.timestamp == searchToRemove.timestamp,
    );
    await saveRecentSearches(searches);
  }

  // Clear all recent searches
  static Future<void> clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
