import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import '../models/maps_models.dart';

class MapWidget extends StatefulWidget {
  final TrainLocation trainLocation;

  const MapWidget({super.key, required this.trainLocation});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _trainMarkerIcon;
  final Map<int, BitmapDescriptor> _stationNumberMarkerCache = {};
  bool _iconsReady = false;

  @override
  void initState() {
    super.initState();
    _prepareMarkerIcons();
    _createPolylines();
  }

  Future<BitmapDescriptor> _createCustomMarker(
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

  Future<BitmapDescriptor> _createNumberMarker(
    int number,
    double size, {
    Color backgroundColor = Colors.red,
  }) async {
    return await Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Text(
        number.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    ).toBitmapDescriptor(
      logicalSize: Size(size, size),
      imageSize: Size(size, size),
    );
  }

  Future<void> _prepareMarkerIcons() async {
    final trainIcon = await _createCustomMarker(
      Icons.train,
      64,
      backgroundColor: Colors.black,
    );
    setState(() {
      _trainMarkerIcon = trainIcon;
      _iconsReady = true;
    });
    _createMarkers();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update markers and polylines if the train location has changed
    if (oldWidget.trainLocation.lat != widget.trainLocation.lat ||
        oldWidget.trainLocation.long != widget.trainLocation.long ||
        oldWidget.trainLocation.speed != widget.trainLocation.speed) {
      _createMarkers();
      _createPolylines();
    }

    // Update camera position to new train location
    _controller?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(widget.trainLocation.lat, widget.trainLocation.long),
      ),
    );
  }

  void _createMarkers() async {
    if (!_iconsReady) return;
    Set<Marker> markers = {};

    // Add train location marker with high zIndexInt
    markers.add(
      Marker(
        markerId: const MarkerId('train'),
        position: LatLng(widget.trainLocation.lat, widget.trainLocation.long),
        infoWindow: InfoWindow(
          title: 'Train Location',
          snippet:
              'Heading ${widget.trainLocation.heading} at '
              '${widget.trainLocation.speed.toStringAsFixed(0)} mph',
        ),
        icon:
            _trainMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndexInt: 100,
      ),
    );

    // Add station markers with stop number as icon, lower zIndexInt
    for (final station in widget.trainLocation.stations) {
      if (station.coordinates != null && station.stopNumber != null) {
        BitmapDescriptor? markerIcon =
            _stationNumberMarkerCache[station.stopNumber!];
        if (markerIcon == null) {
          markerIcon = await _createNumberMarker(
            station.stopNumber!,
            64,
            backgroundColor: Colors.red,
          );
          _stationNumberMarkerCache[station.stopNumber!] = markerIcon;
        }
        markers.add(
          Marker(
            markerId: MarkerId('station_${station.code}'),
            position: LatLng(
              station.coordinates!.latitude,
              station.coordinates!.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Stop ${station.stopNumber}: ${station.code}',
              snippet: station.stationName ?? 'Train station',
            ),
            icon: markerIcon,
            zIndexInt: 1,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _createPolylines() {
    setState(() {
      if (widget.trainLocation.paths.isNotEmpty) {
        Set<Polyline> polylines = {};

        // Create a polyline for each path in the TrainLocation
        for (int i = 0; i < widget.trainLocation.paths.length; i++) {
          final path = widget.trainLocation.paths[i];
          if (path.coordinates.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: PolylineId('route_$i'),
                points: path.coordinates,
                color: Colors.blue,
                width: 4,
                patterns: [],
              ),
            );
          }
        }
        _polylines = polylines;
      } else {
        _polylines = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.trainLocation.lat, widget.trainLocation.long),
          zoom: 8.0,
        ),
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: true,
        scrollGesturesEnabled: true,
        mapToolbarEnabled: false,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
