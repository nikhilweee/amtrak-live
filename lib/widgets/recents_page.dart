import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/recent_service.dart';

class RecentsPage extends StatefulWidget {
  final Function(String trainNumber, DateTime date) onSearchSelected;

  const RecentsPage({super.key, required this.onSearchSelected});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  List<RecentSearch> _recentSearches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await RecentService.loadRecentSearches();
    setState(() {
      _recentSearches = searches;
      _isLoading = false;
    });
  }

  Future<void> _removeSearch(RecentSearch search) async {
    await RecentService.removeRecentSearch(search);
    await _loadRecentSearches();
  }

  Future<void> _clearAllSearches() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Recent Searches'),
        content: const Text(
          'Are you sure you want to clear all recent searches? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RecentService.clearAllRecentSearches();
      await _loadRecentSearches();
    }
  }

  void _selectSearch(RecentSearch search) {
    Navigator.of(context).pop();
    widget.onSearchSelected(search.trainNumber, search.searchDate);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Older - show date
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Searches'),
        forceMaterialTransparency: true,
        actions: _recentSearches.isNotEmpty
            ? [
                IconButton(
                  onPressed: _clearAllSearches,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear All',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentSearches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No recent searches',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your search history will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final search = _recentSearches[index];
                return Dismissible(
                  key: Key(
                    '${search.trainNumber}_${search.timestamp.millisecondsSinceEpoch}',
                  ),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _removeSearch(search);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed search for Train ${search.trainNumber}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.train),
                    title: Text('Train ${search.trainNumber}'),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy').format(search.searchDate),
                    ),
                    trailing: Text(
                      _formatTimestamp(search.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _selectSearch(search),
                  ),
                );
              },
            ),
    );
  }
}
