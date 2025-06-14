// Amtrak Train Data Models
import 'package:timezone/timezone.dart' as tz;

class TrainStop {
  final String id;
  final int stopNumber;
  final String stationCode;
  final String stationName;
  final String stationTimeZone;
  final String? scheduledDeparture;
  final String? actualDeparture;
  final String? status;
  final String? displayMessage;
  final String departuerDateTimeType;

  const TrainStop({
    required this.id,
    required this.stopNumber,
    required this.stationCode,
    required this.stationName,
    required this.stationTimeZone,
    this.scheduledDeparture,
    this.actualDeparture,
    this.status,
    this.displayMessage,
    this.departuerDateTimeType = 'ESTIMATE',
  });

  factory TrainStop.fromJson(Map<String, dynamic> json) {
    final station = json['station'];
    final departure = json['departure'];

    return TrainStop(
      id: json['id'],
      stopNumber: json['stopNumber'],
      stationCode: station['code'],
      stationName: station['name'],
      stationTimeZone: station['timeZone'],
      scheduledDeparture: departure?['schedule']?['dateTime'],
      actualDeparture: departure?['statusInfo']?['dateTime'],
      status: departure?['statusInfo']?['status'],
      displayMessage: departure?['statusInfo']?['displayMessage'],
      departuerDateTimeType:
          departure?['statusInfo']?['dateTimeType'] ?? 'ESTIMATE',
    );
  }

  DateTime? get scheduledTime {
    if (scheduledDeparture == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = DateTime.parse(scheduledDeparture!);
    // Convert to the station's timezone
    final location = tz.getLocation(stationTimeZone);
    return tz.TZDateTime.from(utcDateTime, location);
  }

  DateTime? get actualTime {
    if (actualDeparture == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = DateTime.parse(actualDeparture!);
    // Convert to the station's timezone
    final location = tz.getLocation(stationTimeZone);
    return tz.TZDateTime.from(utcDateTime, location);
  }
}

class TrainData {
  final String id;
  final String trainNumber;
  final String trainName;
  final String date;
  final String originCode;
  final String originName;
  final String destinationCode;
  final String destinationName;
  final String statusMessage;
  final List<TrainStop> stops;

  const TrainData({
    required this.id,
    required this.trainNumber,
    required this.trainName,
    required this.date,
    required this.originCode,
    required this.originName,
    required this.destinationCode,
    required this.destinationName,
    required this.statusMessage,
    required this.stops,
  });

  factory TrainData.fromJson(Map<String, dynamic> json) {
    final travelService = json['travelService'];
    final statusSummary = json['statusSummary'];

    return TrainData(
      id: json['id'],
      trainNumber: travelService['number'],
      trainName: travelService['name']['description'],
      date: travelService['date'],
      originCode: travelService['origin']['code'],
      originName: travelService['origin']['name'],
      destinationCode: travelService['destination']['code'],
      destinationName: travelService['destination']['name'],
      statusMessage: statusSummary['displayMessage'],
      stops: (json['stops'] as List)
          .map((stop) => TrainStop.fromJson(stop))
          .toList(),
    );
  }
}
