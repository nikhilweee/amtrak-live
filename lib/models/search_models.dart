// Amtrak Search Models
class RecentSearch {
  final String trainNumber;
  final DateTime searchDate;
  final DateTime timestamp;

  const RecentSearch({
    required this.trainNumber,
    required this.searchDate,
    required this.timestamp,
  });

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      trainNumber: json['trainNumber'],
      searchDate: DateTime.parse(json['searchDate']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trainNumber': trainNumber,
      'searchDate': searchDate.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Check if this search matches another (same train and date)
  bool matches(String trainNum, DateTime date) {
    return trainNumber == trainNum &&
        searchDate.year == date.year &&
        searchDate.month == date.month &&
        searchDate.day == date.day;
  }
}
