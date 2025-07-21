import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'amtrak_decrypt.dart';

class PreloadService {
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  BitmapDescriptor? trainMarkerIcon;
  BitmapDescriptor? stationMarkerIcon;
  bool _iconsReady = false;
  bool _initialized = false;

  Future<void> preloadAll() async {
    if (_initialized) return;
    // 1. Timezone
    tz.initializeTimeZones();
    // 2. Preload and refresh station/route cache
    await _refreshCacheIfNeeded();
    // 3. Pre-generate marker icons
    await _prepareMarkerIcons();
    _initialized = true;
  }

  Future<void> _refreshCacheIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final stationFile = File('${dir.path}/stations.json');
    final routesFile = File('${dir.path}/routes.json');

    Future<bool> needsRefresh(File file) async {
      if (!await file.exists()) return true;
      final lastMod = await file.lastModified();
      return DateTime.now().difference(lastMod) > Duration(hours: 24);
    }

    debugPrint("Checking for JSON Assets");

    if (await needsRefresh(stationFile)) {
      debugPrint("fetching stations.json");
      final data = await AmtrakDecrypt.getStationData();
      await stationFile.writeAsString(json.encode(data));
    }

    if (await needsRefresh(routesFile)) {
      debugPrint("fetching routes.json");
      final uri = Uri.parse(
        'https://maps.amtrak.com/services/MapDataService/stations/nationalRoute',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        await routesFile.writeAsString(response.body);
      }
    }
  }

  Future<void> _prepareMarkerIcons() async {
    // Pre-generate train marker (black background)
    final trainIcon = await _createIconMarker(
      Icons.train,
      64,
      backgroundColor: Colors.black,
    );
    trainMarkerIcon = trainIcon;
    debugPrint('Generated train marker');

    // Pre-generate station marker (same as train, but red background)
    final stationIcon = await _createIconMarker(
      Icons.train,
      64,
      backgroundColor: Colors.red,
    );
    stationMarkerIcon = stationIcon;
    debugPrint('Generated station marker (red train icon)');

    _iconsReady = true;
  }

  bool get iconsReady => _iconsReady;

  BitmapDescriptor? getTrainMarkerIcon() => trainMarkerIcon;
  BitmapDescriptor? getStationMarker() => stationMarkerIcon;

  Future<BitmapDescriptor> _createIconMarker(
    IconData icon,
    double size, {
    Color backgroundColor = Colors.red,
  }) async {
    return await Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: size * 0.70),
    ).toBitmapDescriptor(
      logicalSize: Size(size, size),
      imageSize: Size(size, size),
    );
  }

  // _createTextMarker is no longer needed and has been removed.
}
