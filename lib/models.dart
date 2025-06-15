// Amtrak Train Data Models
import 'package:timezone/timezone.dart' as tz;

class ArrivalDeparture {
  final String scheduleDateTime;
  final String status;
  final String displayStatus;
  final String displayMessage;
  final String? dateTimeType;
  final String? dateTime;
  final String? delay;
  final String asOf;

  const ArrivalDeparture({
    required this.scheduleDateTime,
    required this.status,
    required this.displayStatus,
    required this.displayMessage,
    this.dateTimeType,
    this.dateTime,
    this.delay,
    required this.asOf,
  });

  factory ArrivalDeparture.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    final statusInfo = json['statusInfo'];

    return ArrivalDeparture(
      scheduleDateTime: schedule['dateTime'],
      status: statusInfo['status'],
      displayStatus: statusInfo['displayStatus'],
      displayMessage: statusInfo['displayMessage'],
      dateTimeType: statusInfo?['dateTimeType'],
      dateTime: statusInfo?['dateTime'],
      delay: statusInfo?['delay'],
      asOf: statusInfo['asOf'],
    );
  }

  DateTime get scheduledTime {
    return DateTime.parse(scheduleDateTime);
  }

  DateTime? get actualTime {
    if (dateTime == null) return null;
    return DateTime.parse(dateTime!);
  }

  DateTime get asOfTime {
    return DateTime.parse(asOf);
  }
}

class TrainStop {
  final String id;
  final int stopNumber;
  final String stationCode;
  final String stationName;
  final String? stationFacility;
  final String stationTimeZone;
  final ArrivalDeparture? arrival;
  final ArrivalDeparture? departure;

  const TrainStop({
    required this.id,
    required this.stopNumber,
    required this.stationCode,
    required this.stationName,
    this.stationFacility,
    required this.stationTimeZone,
    this.arrival,
    this.departure,
  });

  factory TrainStop.fromJson(Map<String, dynamic> json) {
    final station = json['station'];
    final arrivalJson = json['arrival'];
    final departureJson = json['departure'];

    return TrainStop(
      id: json['id'],
      stopNumber: json['stopNumber'],
      stationCode: station['code'],
      stationName: station['name'],
      stationFacility: station?['facility'],
      stationTimeZone: station['timeZone'],
      arrival: arrivalJson != null
          ? ArrivalDeparture.fromJson(arrivalJson)
          : null,
      departure: departureJson != null
          ? ArrivalDeparture.fromJson(departureJson)
          : null,
    );
  }

  DateTime? get scheduledArrivalTime {
    if (arrival == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = arrival!.scheduledTime;
    // Convert to the station's timezone
    final location = tz.getLocation(stationTimeZone);
    return tz.TZDateTime.from(utcDateTime, location);
  }

  DateTime? get actualArrivalTime {
    if (arrival?.actualTime == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = arrival!.actualTime!;
    // Convert to the station's timezone
    final location = tz.getLocation(stationTimeZone);
    return tz.TZDateTime.from(utcDateTime, location);
  }

  DateTime? get scheduledDepartureTime {
    if (departure == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = departure!.scheduledTime;
    // Convert to the station's timezone
    final location = tz.getLocation(stationTimeZone);
    return tz.TZDateTime.from(utcDateTime, location);
  }

  DateTime? get actualDepartureTime {
    if (departure?.actualTime == null) return null;
    // Parse the datetime with timezone offset
    final utcDateTime = departure!.actualTime!;
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
